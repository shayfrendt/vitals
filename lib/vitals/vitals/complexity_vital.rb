# frozen_string_literal: true

require "rubocop"
require "flog"
require "tempfile"
require "json"

module Vitals
  module Vitals
    class ComplexityVital < BaseVital
      def check(path:)
        expanded_path = File.expand_path(path)

        unless File.exist?(expanded_path)
          raise Error, "Path does not exist: #{expanded_path}"
        end

        rubocop_results = run_rubocop_complexity(expanded_path)
        flog_results = run_flog(expanded_path)

        score = calculate_score(rubocop_results, flog_results)
        violations = extract_violations(rubocop_results)

        create_result(
          score: score,
          violations: violations,
          metadata: {
            average_complexity: calculate_average(rubocop_results),
            methods_over_threshold: count_violations(rubocop_results),
            worst_offenders: top_offenders(rubocop_results, limit: 10),
            total_methods_analyzed: rubocop_results[:total_methods],
            flog_average: flog_results[:average],
            flog_total: flog_results[:total]
          }
        )
      end

      private

      def run_rubocop_complexity(path)
        # Create a temporary config file to only run complexity cops
        config_content = <<~YAML
          AllCops:
            NewCops: disable

          Metrics/CyclomaticComplexity:
            Enabled: true
            Max: #{threshold}

          Metrics/PerceivedComplexity:
            Enabled: true
            Max: #{threshold}

          Metrics/AbcSize:
            Enabled: true
            Max: 15
        YAML

        Tempfile.create(["rubocop_config", ".yml"]) do |config_file|
          config_file.write(config_content)
          config_file.flush

          options = {
            formatters: [["json", nil]],
            config: config_file.path
          }

          runner = RuboCop::Runner.new(options, RuboCop::ConfigStore.new)

          # Capture output
          output = StringIO.new
          original_stdout = $stdout
          $stdout = output

          begin
            runner.run([path])
          ensure
            $stdout = original_stdout
          end

          parse_rubocop_output(output.string)
        end
      end

      def parse_rubocop_output(json_output)
        return default_rubocop_results if json_output.empty?

        data = JSON.parse(json_output)
        files = data["files"] || []

        offenses = []
        total_complexity = 0
        total_methods = 0

        files.each do |file|
          next unless file["offenses"]

          file["offenses"].each do |offense|
            next unless complexity_cop?(offense["cop_name"])

            offenses << {
              file: file["path"],
              line: offense["location"]["start_line"],
              cop: offense["cop_name"],
              message: offense["message"],
              severity: offense["severity"]
            }

            # Extract complexity number from message if available
            if offense["message"] =~ /complexity of (\d+)/
              total_complexity += $1.to_i
              total_methods += 1
            end
          end
        end

        {
          offenses: offenses,
          total_complexity: total_complexity,
          total_methods: total_methods > 0 ? total_methods : offenses.length
        }
      rescue JSON::ParserError
        default_rubocop_results
      end

      def default_rubocop_results
        { offenses: [], total_complexity: 0, total_methods: 0 }
      end

      def complexity_cop?(cop_name)
        cop_name.start_with?("Metrics/")
      end

      def run_flog(path)
        flog = Flog.new(continue: true)

        if File.directory?(path)
          ruby_files = Dir.glob(File.join(path, "**", "*.rb"))
          ruby_files.each { |file| flog.flog(file) }
        else
          flog.flog(path)
        end

        {
          total: flog.total,
          average: flog.average,
          scores: flog.totals
        }
      rescue StandardError => e
        # If Flog fails, return empty results
        { total: 0, average: 0, scores: {} }
      end

      def calculate_score(rubocop_results, flog_results)
        # Score out of 100 based on violations
        total_methods = rubocop_results[:total_methods]
        return 100 if total_methods.zero?

        violations_count = rubocop_results[:offenses].length
        violation_rate = violations_count.to_f / total_methods

        # 100 score if no violations, scales down based on violation rate
        # Max penalty is 60 points (minimum score is 40 if every method has violations)
        penalty = [violation_rate * 60, 60].min

        score = (100 - penalty).round
        [score, 0].max # Ensure score is at least 0
      end

      def calculate_average(rubocop_results)
        total_methods = rubocop_results[:total_methods]
        return 0 if total_methods.zero?

        (rubocop_results[:total_complexity].to_f / total_methods).round(2)
      end

      def count_violations(rubocop_results)
        rubocop_results[:offenses].length
      end

      def extract_violations(rubocop_results)
        rubocop_results[:offenses].map do |offense|
          {
            file: offense[:file],
            line: offense[:line],
            message: offense[:message],
            severity: offense[:severity]
          }
        end
      end

      def top_offenders(rubocop_results, limit: 10)
        rubocop_results[:offenses]
          .sort_by { |o| extract_complexity_from_message(o[:message]) }
          .reverse
          .take(limit)
          .map do |offense|
            {
              location: "#{offense[:file]}:#{offense[:line]}",
              message: offense[:message],
              complexity: extract_complexity_from_message(offense[:message])
            }
          end
      end

      def extract_complexity_from_message(message)
        match = message.match(/complexity of (\d+)/)
        match ? match[1].to_i : 0
      end
    end
  end
end
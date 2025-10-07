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
        validate_path_exists(expanded_path)

        rubocop_results = run_rubocop_complexity(expanded_path)
        flog_results = run_flog(expanded_path)

        build_complexity_result(rubocop_results, flog_results)
      end

      def validate_path_exists(path)
        return if File.exist?(path)

        raise Error, "Path does not exist: #{path}"
      end

      def build_complexity_result(rubocop_results, flog_results)
        score = calculate_score(rubocop_results, flog_results)
        violations = extract_violations(rubocop_results)

        create_result(
          score: score,
          violations: violations,
          metadata: build_complexity_metadata(rubocop_results, flog_results)
        )
      end

      def build_complexity_metadata(rubocop_results, flog_results)
        {
          average_complexity: calculate_average(rubocop_results),
          methods_over_threshold: count_violations(rubocop_results),
          worst_offenders: top_offenders(rubocop_results, limit: 10),
          total_methods_analyzed: rubocop_results[:total_methods],
          flog_average: flog_results[:average],
          flog_total: flog_results[:total]
        }
      end

      private

      def run_rubocop_complexity(path)
        Tempfile.create(["rubocop_config", ".yml"]) do |config_file|
          write_rubocop_config(config_file)
          run_rubocop_with_config(path, config_file.path)
        end
      end

      def write_rubocop_config(config_file)
        config_file.write(rubocop_config_content)
        config_file.flush
      end

      def rubocop_config_content
        <<~YAML
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
      end

      def run_rubocop_with_config(path, config_path)
        options = { formatters: [["json", nil]], config: config_path }
        runner = RuboCop::Runner.new(options, RuboCop::ConfigStore.new)

        output = capture_rubocop_output { runner.run([path]) }
        parse_rubocop_output(output)
      end

      def capture_rubocop_output
        output = StringIO.new
        original_stdout = $stdout
        $stdout = output

        begin
          yield
        ensure
          $stdout = original_stdout
        end

        output.string
      end

      def parse_rubocop_output(json_output)
        return default_rubocop_results if json_output.empty?

        data = JSON.parse(json_output)
        files = data["files"] || []

        offenses = []
        complexity_data = { total: 0, count: 0 }

        files.each { |file| process_file_offenses(file, offenses, complexity_data) }

        build_rubocop_results(offenses, complexity_data)
      rescue JSON::ParserError
        default_rubocop_results
      end

      def process_file_offenses(file, offenses, complexity_data)
        return unless file["offenses"]

        file["offenses"].each do |offense|
          next unless complexity_cop?(offense["cop_name"])

          offenses << build_offense(file["path"], offense)
          extract_complexity(offense["message"], complexity_data)
        end
      end

      def build_offense(path, offense)
        {
          file: path,
          line: offense["location"]["start_line"],
          cop: offense["cop_name"],
          message: offense["message"],
          severity: offense["severity"]
        }
      end

      def extract_complexity(message, complexity_data)
        return unless message =~ /complexity of (\d+)/

        complexity_data[:total] += $1.to_i
        complexity_data[:count] += 1
      end

      def build_rubocop_results(offenses, complexity_data)
        method_count = complexity_data[:count].positive? ? complexity_data[:count] : offenses.length

        {
          offenses: offenses,
          total_complexity: complexity_data[:total],
          total_methods: method_count
        }
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
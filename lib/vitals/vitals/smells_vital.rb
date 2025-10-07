# frozen_string_literal: true

require "reek"
require "rubycritic"
require "tempfile"
require "json"

module Vitals
  module Vitals
    class SmellsVital < BaseVital
      def check(path:)
        expanded_path = File.expand_path(path)

        unless File.exist?(expanded_path)
          raise Error, "Path does not exist: #{expanded_path}"
        end

        reek_results = run_reek(expanded_path)
        rubycritic_score = run_rubycritic(expanded_path)

        score = rubycritic_score || calculate_score_from_reek(reek_results)
        violations = extract_violations(reek_results)

        create_result(
          score: score,
          violations: violations,
          metadata: {
            total_smells: reek_results.length,
            smell_distribution: categorize_smells(reek_results),
            rubycritic_score: rubycritic_score
          }
        )
      end

      private

      def run_reek(path)
        # Configure Reek
        configuration = Reek::Configuration::AppConfiguration.default

        # Examine the path
        examiner = if File.directory?(path)
                     Reek::Examiner.new(Dir.glob(File.join(path, "**", "*.rb")), configuration: configuration)
                   else
                     Reek::Examiner.new([path], configuration: configuration)
                   end

        # Get smells
        examiner.smells.map do |smell|
          {
            file: smell.source,
            line: smell.lines.first,
            type: smell.smell_type,
            message: smell.message,
            context: smell.context
          }
        end
      rescue StandardError => e
        # If Reek fails, return empty results
        []
      end

      def run_rubycritic(path)
        # RubyCritic writes to filesystem, so we'll capture its score
        # Run in a temporary directory to avoid polluting the project
        Dir.mktmpdir do |tmpdir|
          in_temp_dir(tmpdir) { analyze_with_rubycritic(path) }
        end
      rescue StandardError
        # If RubyCritic fails, return nil to fall back to Reek-based scoring
        nil
      end

      def in_temp_dir(tmpdir)
        old_dir = Dir.pwd
        Dir.chdir(tmpdir)
        yield
      ensure
        Dir.chdir(old_dir)
      end

      def analyze_with_rubycritic(path)
        paths = collect_ruby_files(path)
        return nil if paths.empty?

        analysed_modules = run_rubycritic_analysis(paths)
        calculate_rubycritic_score(analysed_modules)
      end

      def collect_ruby_files(path)
        if File.directory?(path)
          Dir.glob(File.join(path, "**", "*.rb"))
        else
          [path]
        end
      end

      def run_rubycritic_analysis(paths)
        analyser = RubyCritic::AnalysersRunner.new(paths)
        analyser.run
      end

      def calculate_rubycritic_score(analysed_modules)
        return 100 if analysed_modules.empty? # No modules to analyze means perfect score

        total_score = analysed_modules.sum { |mod| mod.rating.to_f }
        average_rating = total_score / analysed_modules.length

        # Convert rating (A=4, B=3, C=2, D=1, F=0) to 0-100 scale
        # A=100, B=75, C=50, D=25, F=0
        (average_rating * 25).round
      end

      def calculate_score_from_reek(reek_results)
        # If no smells found, perfect score
        return 100 if reek_results.empty?

        # Simple scoring: reduce score based on number of smells
        # Assume 1 smell per 10 methods is acceptable (score of 90)
        # More smells reduce the score
        smell_count = reek_results.length

        # Penalize based on smell count
        # 0 smells = 100, 5 smells = 90, 10 smells = 80, etc.
        penalty = [smell_count * 2, 80].min
        score = 100 - penalty

        [score, 20].max # Minimum score of 20
      end

      def extract_violations(reek_results)
        reek_results.map do |smell|
          {
            file: smell[:file],
            line: smell[:line],
            type: smell[:type],
            message: smell[:message],
            context: smell[:context]
          }
        end
      end

      def categorize_smells(reek_results)
        reek_results.group_by { |smell| smell[:type] }
                    .transform_values(&:count)
                    .sort_by { |_, count| -count }
                    .to_h
      end
    end
  end
end
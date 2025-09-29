# frozen_string_literal: true

require "simplecov"
require "json"

module Vitals
  module Vitals
    class CoverageVital < BaseVital
      def check(path:)
        expanded_path = File.expand_path(path)

        unless File.exist?(expanded_path)
          raise Error, "Path does not exist: #{expanded_path}"
        end

        coverage_data = find_coverage_data(expanded_path)

        if coverage_data.nil?
          raise Error, "No coverage data found. Run your tests with SimpleCov enabled first."
        end

        score = coverage_data[:line_coverage]
        violations = identify_uncovered_files(coverage_data, expanded_path)

        create_result(
          score: score,
          violations: violations,
          metadata: {
            line_coverage: coverage_data[:line_coverage],
            branch_coverage: coverage_data[:branch_coverage],
            total_lines: coverage_data[:total_lines],
            covered_lines: coverage_data[:covered_lines],
            uncovered_critical_paths: violations.take(10)
          }
        )
      end

      private

      def find_coverage_data(path)
        # Look for SimpleCov resultset in common locations
        project_root = find_project_root(path)
        resultset_path = File.join(project_root, "coverage", ".resultset.json")

        return nil unless File.exist?(resultset_path)

        parse_resultset(resultset_path)
      end

      def find_project_root(path)
        # Walk up the directory tree to find project root
        # Look for Gemfile, .git, or other indicators
        current = File.directory?(path) ? path : File.dirname(path)

        loop do
          return current if File.exist?(File.join(current, "Gemfile")) ||
                            File.exist?(File.join(current, ".git"))

          parent = File.dirname(current)
          break if parent == current # Reached root

          current = parent
        end

        # If no project root found, use the given path's directory
        File.directory?(path) ? path : File.dirname(path)
      end

      def parse_resultset(resultset_path)
        data = JSON.parse(File.read(resultset_path))

        # SimpleCov stores results under different keys (RSpec, etc.)
        # Get the first result set
        result_set = data.values.first
        return nil unless result_set

        coverage_data = result_set["coverage"] || {}

        total_lines = 0
        covered_lines = 0
        files_data = []

        coverage_data.each do |file_path, file_coverage|
          next if file_coverage.nil? || file_coverage.empty?

          # Handle both array format (line coverage) and hash format (branch coverage)
          lines = if file_coverage.is_a?(Hash)
                    file_coverage["lines"] || []
                  else
                    file_coverage
                  end

          file_total = lines.compact.length
          file_covered = lines.count { |hits| hits && hits > 0 }

          total_lines += file_total
          covered_lines += file_covered

          files_data << {
            file: file_path,
            total_lines: file_total,
            covered_lines: file_covered,
            coverage_percent: file_total > 0 ? (file_covered.to_f / file_total * 100).round(2) : 100
          }
        end

        line_coverage = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 100

        {
          line_coverage: line_coverage,
          branch_coverage: line_coverage, # Simplified - branch coverage requires more complex parsing
          total_lines: total_lines,
          covered_lines: covered_lines,
          files: files_data
        }
      rescue JSON::ParserError, StandardError => e
        nil
      end

      def identify_uncovered_files(coverage_data, path)
        return [] unless coverage_data[:files]

        # Find files with coverage below threshold
        coverage_data[:files]
          .select { |file_data| file_data[:coverage_percent] < threshold }
          .sort_by { |file_data| file_data[:coverage_percent] }
          .map do |file_data|
            {
              file: file_data[:file],
              coverage_percent: file_data[:coverage_percent],
              covered_lines: file_data[:covered_lines],
              total_lines: file_data[:total_lines],
              message: "Coverage #{file_data[:coverage_percent]}% (below threshold of #{threshold}%)"
            }
          end
      end
    end
  end
end
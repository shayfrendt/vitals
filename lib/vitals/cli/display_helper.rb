# frozen_string_literal: true

module Vitals
  # Helper class to handle CLI display output formatting
  class CLIDisplayHelper
      def self.vital_header(path, header_text)
        puts "#{header_text}: #{File.expand_path(path)}"
        puts "━" * 50
      end

      def self.check_header(path)
        puts "🏥 Running vitals check on: #{File.expand_path(path)}"
        puts "━" * 50
      end

      def self.report_header(path)
        puts "📊 Generating health report for: #{File.expand_path(path)}"
        puts "━" * 50
      end

      def self.result_summary(result)
        threshold = result.score >= 80 ? 80 : 0
        status = result.healthy?(threshold: threshold) ? "🟢 HEALTHY" : "🔴 NEEDS ATTENTION"

        puts "\n📊 Result:"
        puts "  Score: #{result.score}/100"
        puts "  Status: #{status}"
        puts "  Violations: #{result.violations.length}"
      end

      def self.violations_list(violations)
        return unless violations.any?

        if violations.length <= 10
          puts "\n⚠️  Top violations:"
        else
          puts "\n⚠️  #{violations.length} violations found (showing first 10):"
        end

        violations.take(10).each do |violation|
          puts "  • #{violation[:file]}:#{violation[:line]} - #{violation[:message] || violation[:type]}"
        end
      end

      def self.completion_message
        puts "\n✓ Analysis complete"
      end
  end
end

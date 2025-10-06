# frozen_string_literal: true

module Vitals
  module Reporters
    class CliReporter < BaseReporter
      def render
        output = []

        output << "╔═══════════════════════════════════════════╗"
        output << "║   CODEBASE HEALTH REPORT                  ║"
        output << "╠═══════════════════════════════════════════╣"
        output << "║   Overall Score: #{report.overall_score}/100"
        output << "║   Status: #{status_emoji(report.health_status)} #{report.health_status.to_s.upcase.tr('_', ' ')}"
        output << "╠═══════════════════════════════════════════╣"

        report.vital_results.each do |result|
          threshold = threshold_for_vital(result.vital)
          status = result.healthy?(threshold: threshold) ? "🟢" : "🔴"
          output << "║   #{result.vital.to_s.capitalize} Vital: #{status} #{result.score}/100"
        end

        output << "╠═══════════════════════════════════════════╣"

        if report.recommendations.any?
          output << "║   Recommendations:"
          report.recommendations.each do |rec|
            output << "║   • #{rec}"
          end
        else
          output << "║   ✓ All vitals are healthy!"
        end

        output << "╚═══════════════════════════════════════════╝"

        output.join("\n")
      end

      def render_summary
        output = []

        output << "━" * 50
        output << "📊 HEALTH REPORT"
        output << "━" * 50
        output << ""
        output << " Overall Score: #{report.overall_score}/100 (#{report.health_status.to_s.upcase.tr('_', ' ')})"

        report.vital_results.each do |result|
          threshold = threshold_for_vital(result.vital)
          status = result.healthy?(threshold: threshold) ? "🟢 PASS" : "🔴 FAIL"

          output << ""
          output << "#{result.vital.to_s.capitalize}: #{status}"
          output << "  Score: #{result.score}/100 (threshold: #{threshold})"
          output << "  Violations: #{result.violations.length}"
        end

        if report.recommendations.any?
          output << ""
          output << "💡 Recommendations:"
          report.recommendations.each do |rec|
            output << "  • #{rec}"
          end
        end

        output << ""
        output << "━" * 50

        output.join("\n")
      end

      private

      def status_emoji(status)
        case status
        when :excellent then "🟢"
        when :good then "🟢"
        when :needs_improvement then "🟡"
        when :high_risk then "🔴"
        else "⚪"
        end
      end
    end
  end
end
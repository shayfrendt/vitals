# frozen_string_literal: true

module Vitals
  module Reporters
    class CliReporter < BaseReporter
      def render
        output = []
        output.concat(render_header)
        output.concat(render_vitals)
        output << "╠═══════════════════════════════════════════╣"
        output.concat(render_recommendations)
        output << "╚═══════════════════════════════════════════╝"
        output.join("\n")
      end

      def render_summary
        output = []
        output << "━" * 50
        output << "📊 HEALTH REPORT"
        output << "━" * 50
        output << ""
        output << format_overall_score
        output.concat(render_vital_summaries)
        output.concat(render_summary_recommendations) if report.recommendations.any?
        output << ""
        output << "━" * 50
        output.join("\n")
      end

      private

      def render_header
        [
          "╔═══════════════════════════════════════════╗",
          "║   CODEBASE HEALTH REPORT                  ║",
          "╠═══════════════════════════════════════════╣",
          "║   Overall Score: #{report.overall_score}/100",
          "║   Status: #{status_emoji(report.health_status)} #{format_status_text(report.health_status)}",
          "╠═══════════════════════════════════════════╣"
        ]
      end

      def render_vitals
        report.vital_results.map do |result|
          threshold = threshold_for_vital(result.vital)
          status = result.healthy?(threshold: threshold) ? "🟢" : "🔴"
          "║   #{result.vital.to_s.capitalize} Vital: #{status} #{result.score}/100"
        end
      end

      def render_recommendations
        return ["║   ✓ All vitals are healthy!"] if report.recommendations.empty?

        output = ["║   Recommendations:"]
        report.recommendations.each { |rec| output << "║   • #{rec}" }
        output
      end

      def format_overall_score
        " Overall Score: #{report.overall_score}/100 (#{format_status_text(report.health_status)})"
      end

      def render_vital_summaries
        output = []
        report.vital_results.each do |result|
          threshold = threshold_for_vital(result.vital)
          status = result.healthy?(threshold: threshold) ? "🟢 PASS" : "🔴 FAIL"
          output << ""
          output << "#{result.vital.to_s.capitalize}: #{status}"
          output << "  Score: #{result.score}/100 (threshold: #{threshold})"
          output << "  Violations: #{result.violations.length}"
        end
        output
      end

      def render_summary_recommendations
        output = ["", "💡 Recommendations:"]
        report.recommendations.each { |rec| output << "  • #{rec}" }
        output
      end

      def format_status_text(status)
        status.to_s.upcase.tr("_", " ")
      end

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
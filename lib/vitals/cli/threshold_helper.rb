# frozen_string_literal: true

module Vitals
  # Helper class to handle threshold-related operations
  class CLIThresholdHelper
      def self.for_vital(vital, config)
        case vital
        when :complexity
          config.complexity[:threshold]
        when :smells
          config.smells[:threshold]
        when :coverage
          config.coverage[:threshold]
        else
          0
        end
      end

      def self.all_healthy?(health_report, config)
        health_report.vital_results.all? do |result|
          threshold = for_vital(result.vital, config)
          result.healthy?(threshold: threshold)
        end
      end

      def self.exit_code_for(health_report, config)
        all_healthy?(health_report, config) ? 0 : 1
      end
  end
end

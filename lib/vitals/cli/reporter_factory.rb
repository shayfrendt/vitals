# frozen_string_literal: true

module Vitals
  # Factory class to create appropriate reporters based on format
  class CLIReporterFactory
      def self.create(format:, report:, config:)
        case format
        when "json"
          Reporters::JsonReporter.new(report: report, config: config)
        when "html"
          # HTML reporter not implemented yet
          Reporters::CliReporter.new(report: report, config: config)
        else
          Reporters::CliReporter.new(report: report, config: config)
        end
      end

      def self.for_result(result:, config:)
        health_report = HealthReport.new(vital_results: [result], config: config)
        create(format: nil, report: health_report, config: config)
      end
  end
end

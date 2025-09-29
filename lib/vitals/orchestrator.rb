# frozen_string_literal: true

module Vitals
  class Orchestrator
    attr_reader :config, :vitals_to_run

    def initialize(config:, vitals: [:complexity, :smells, :coverage])
      @config = config
      @vitals_to_run = vitals
    end

    # Run selected vitals and return a HealthReport
    def run(path:)
      results = []

      vitals_to_run.each do |vital_name|
        vital = create_vital(vital_name)

        begin
          result = vital.check(path: path)
          results << result
        rescue Error => e
          # If a vital check fails (e.g., no coverage data), skip it
          # Don't fail the entire run
          warn "⚠️  Skipping #{vital_name}: #{e.message}" if ENV["DEBUG"]
        end
      end

      HealthReport.new(vital_results: results, config: config)
    end

    private

    def create_vital(vital_name)
      case vital_name
      when :complexity
        Vitals::ComplexityVital.new(config: config)
      when :smells
        Vitals::SmellsVital.new(config: config)
      when :coverage
        Vitals::CoverageVital.new(config: config)
      else
        raise Error, "Unknown vital: #{vital_name}"
      end
    end
  end
end
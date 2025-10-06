# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vitals::Reporters::CliReporter do
  let(:config) { Vitals::Config.new }
  let(:complexity_result) do
    Vitals::VitalResult.new(
      vital: :complexity,
      score: 85,
      violations: [],
      metadata: {}
    )
  end
  let(:smells_result) do
    Vitals::VitalResult.new(
      vital: :smells,
      score: 90,
      violations: [],
      metadata: {}
    )
  end
  let(:vital_results) { [complexity_result, smells_result] }
  let(:health_report) do
    Vitals::HealthReport.new(vital_results: vital_results, config: config)
  end
  let(:reporter) { described_class.new(report: health_report, config: config) }

  describe "#render" do
    it "returns a formatted string report" do
      output = reporter.render
      expect(output).to be_a(String)
      expect(output).to include("CODEBASE HEALTH REPORT")
      expect(output).to include("Overall Score")
      expect(output).to include("Complexity Vital")
      expect(output).to include("Smells Vital")
    end

    it "includes health status" do
      output = reporter.render
      expect(output).to match(/GOOD|EXCELLENT|NEEDS IMPROVEMENT|HIGH RISK/)
    end

    it "shows recommendations when vitals are unhealthy" do
      unhealthy_result = Vitals::VitalResult.new(
        vital: :complexity,
        score: 30,
        violations: [{file: "test.rb", line: 1, message: "Too complex"}],
        metadata: {}
      )
      bad_report = Vitals::HealthReport.new(vital_results: [unhealthy_result], config: config)
      bad_reporter = described_class.new(report: bad_report, config: config)

      output = bad_reporter.render
      expect(output).to include("Recommendations")
    end
  end

  describe "#render_summary" do
    it "returns a formatted summary string" do
      output = reporter.render_summary
      expect(output).to be_a(String)
      expect(output).to include("HEALTH REPORT")
      expect(output).to include("Overall Score")
    end

    it "shows pass/fail status for each vital" do
      output = reporter.render_summary
      expect(output).to include("PASS")
      expect(output).to include("Score:")
      expect(output).to include("Violations:")
    end
  end
end
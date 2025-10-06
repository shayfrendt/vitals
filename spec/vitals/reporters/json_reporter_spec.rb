# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe Vitals::Reporters::JsonReporter do
  let(:config) { Vitals::Config.new }
  let(:complexity_result) do
    Vitals::VitalResult.new(
      vital: :complexity,
      score: 85,
      violations: [],
      metadata: {}
    )
  end
  let(:vital_results) { [complexity_result] }
  let(:health_report) do
    Vitals::HealthReport.new(vital_results: vital_results, config: config)
  end
  let(:reporter) { described_class.new(report: health_report, config: config) }

  describe "#render" do
    it "returns a JSON string" do
      output = reporter.render
      expect(output).to be_a(String)

      # Verify it's valid JSON
      parsed = JSON.parse(output)
      expect(parsed).to be_a(Hash)
    end

    it "includes overall_score in JSON" do
      output = reporter.render
      parsed = JSON.parse(output)

      expect(parsed).to have_key("overall_score")
      expect(parsed["overall_score"]).to be_a(Numeric)
    end

    it "includes health_status in JSON" do
      output = reporter.render
      parsed = JSON.parse(output)

      expect(parsed).to have_key("health_status")
      expect(parsed["health_status"]).to be_a(String)
    end

    it "includes vitals array in JSON" do
      output = reporter.render
      parsed = JSON.parse(output)

      expect(parsed).to have_key("vitals")
      expect(parsed["vitals"]).to be_an(Array)
      expect(parsed["vitals"].first).to have_key("vital")
      expect(parsed["vitals"].first).to have_key("score")
    end

    it "includes recommendations in JSON" do
      output = reporter.render
      parsed = JSON.parse(output)

      expect(parsed).to have_key("recommendations")
      expect(parsed["recommendations"]).to be_an(Array)
    end
  end
end
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vitals::Reporters::BaseReporter do
  let(:config) { Vitals::Config.new }
  let(:result) { Vitals::VitalResult.new(vital: :complexity, score: 85, violations: [], metadata: {}) }
  let(:report) { Vitals::HealthReport.new(vital_results: [result], config: config) }

  # Create a concrete implementation for testing
  let(:concrete_reporter) do
    Class.new(described_class) do
      def render
        "test output"
      end
    end
  end

  describe "#initialize" do
    it "requires a report" do
      reporter = concrete_reporter.new(report: report, config: config)
      expect(reporter.report).to eq(report)
      expect(reporter.config).to eq(config)
    end
  end

  describe "#render" do
    it "raises NotImplementedError in base class" do
      base_reporter = described_class.new(report: report, config: config)
      expect { base_reporter.render }.to raise_error(NotImplementedError)
    end

    it "can be implemented by subclasses" do
      reporter = concrete_reporter.new(report: report, config: config)
      expect(reporter.render).to eq("test output")
    end
  end

  describe "#threshold_for_vital" do
    let(:reporter) { concrete_reporter.new(report: report, config: config) }

    it "returns complexity threshold" do
      expect(reporter.send(:threshold_for_vital, :complexity)).to eq(90)
    end

    it "returns smells threshold" do
      expect(reporter.send(:threshold_for_vital, :smells)).to eq(80)
    end

    it "returns coverage threshold" do
      expect(reporter.send(:threshold_for_vital, :coverage)).to eq(90)
    end

    it "returns 0 for unknown vital" do
      expect(reporter.send(:threshold_for_vital, :unknown)).to eq(0)
    end
  end
end

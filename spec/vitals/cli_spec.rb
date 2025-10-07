# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vitals::CLI do
  describe "helper classes" do
    describe "CLIThresholdHelper" do
      let(:config) { Vitals::Config.new }

      it "returns complexity threshold" do
        threshold = Vitals::CLIThresholdHelper.for_vital(:complexity, config)
        expect(threshold).to eq(90)
      end

      it "returns smells threshold" do
        threshold = Vitals::CLIThresholdHelper.for_vital(:smells, config)
        expect(threshold).to eq(80)
      end

      it "returns coverage threshold" do
        threshold = Vitals::CLIThresholdHelper.for_vital(:coverage, config)
        expect(threshold).to eq(90)
      end

      it "returns 0 for unknown vital" do
        threshold = Vitals::CLIThresholdHelper.for_vital(:unknown, config)
        expect(threshold).to eq(0)
      end
    end

    describe "CLIReporterFactory" do
      let(:config) { Vitals::Config.new }
      let(:result) { Vitals::VitalResult.new(vital: :complexity, score: 85, violations: [], metadata: {}) }
      let(:report) { Vitals::HealthReport.new(vital_results: [result], config: config) }

      it "creates JSON reporter when format is json" do
        reporter = Vitals::CLIReporterFactory.create(format: "json", report: report, config: config)
        expect(reporter).to be_a(Vitals::Reporters::JsonReporter)
      end

      it "creates CLI reporter when format is cli" do
        reporter = Vitals::CLIReporterFactory.create(format: "cli", report: report, config: config)
        expect(reporter).to be_a(Vitals::Reporters::CliReporter)
      end

      it "creates CLI reporter by default" do
        reporter = Vitals::CLIReporterFactory.create(format: nil, report: report, config: config)
        expect(reporter).to be_a(Vitals::Reporters::CliReporter)
      end
    end

    describe "CLIConfigManager" do
      it "loads default config when no path specified" do
        manager = Vitals::CLIConfigManager.new({})
        config = manager.load_with_overrides
        expect(config).to be_a(Vitals::Config)
        expect(config.complexity[:threshold]).to eq(90)
      end

      it "applies complexity threshold override" do
        manager = Vitals::CLIConfigManager.new({ complexity_threshold: 50 })
        config = manager.load_with_overrides
        expect(config.complexity[:threshold]).to eq(50)
      end

      it "applies smells threshold override" do
        manager = Vitals::CLIConfigManager.new({ smells_threshold: 60 })
        config = manager.load_with_overrides
        expect(config.smells[:threshold]).to eq(60)
      end

      it "applies coverage threshold override" do
        manager = Vitals::CLIConfigManager.new({ coverage_threshold: 70 })
        config = manager.load_with_overrides
        expect(config.coverage[:threshold]).to eq(70)
      end
    end
  end
end

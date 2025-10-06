# frozen_string_literal: true

require "spec_helper"

RSpec.describe Vitals::CLI do
  describe "helper methods" do
    let(:cli) { described_class.new }

    describe "#threshold_for_vital" do
      let(:config) { Vitals::Config.new }

      it "returns complexity threshold" do
        threshold = cli.send(:threshold_for_vital, :complexity, config)
        expect(threshold).to eq(90)
      end

      it "returns smells threshold" do
        threshold = cli.send(:threshold_for_vital, :smells, config)
        expect(threshold).to eq(80)
      end

      it "returns coverage threshold" do
        threshold = cli.send(:threshold_for_vital, :coverage, config)
        expect(threshold).to eq(90)
      end

      it "returns 0 for unknown vital" do
        threshold = cli.send(:threshold_for_vital, :unknown, config)
        expect(threshold).to eq(0)
      end
    end

    describe "#create_reporter" do
      let(:config) { Vitals::Config.new }
      let(:result) { Vitals::VitalResult.new(vital: :complexity, score: 85, violations: [], metadata: {}) }
      let(:report) { Vitals::HealthReport.new(vital_results: [result], config: config) }

      it "creates JSON reporter when format is json" do
        cli.instance_variable_set(:@options, { format: "json" })
        reporter = cli.send(:create_reporter, report, config)
        expect(reporter).to be_a(Vitals::Reporters::JsonReporter)
      end

      it "creates CLI reporter when format is cli" do
        cli.instance_variable_set(:@options, { format: "cli" })
        reporter = cli.send(:create_reporter, report, config)
        expect(reporter).to be_a(Vitals::Reporters::CliReporter)
      end

      it "creates CLI reporter by default" do
        cli.instance_variable_set(:@options, {})
        reporter = cli.send(:create_reporter, report, config)
        expect(reporter).to be_a(Vitals::Reporters::CliReporter)
      end
    end

    describe "#load_config" do
      it "loads default config when no path specified" do
        cli.instance_variable_set(:@options, {})
        config = cli.send(:load_config)
        expect(config).to be_a(Vitals::Config)
        expect(config.complexity[:threshold]).to eq(90)
      end
    end

    describe "#apply_option_overrides" do
      it "applies complexity threshold override" do
        config = Vitals::Config.new
        cli.instance_variable_set(:@options, { complexity_threshold: 50 })
        cli.send(:apply_option_overrides, config)
        expect(config.complexity[:threshold]).to eq(50)
      end

      it "applies smells threshold override" do
        config = Vitals::Config.new
        cli.instance_variable_set(:@options, { smells_threshold: 60 })
        cli.send(:apply_option_overrides, config)
        expect(config.smells[:threshold]).to eq(60)
      end

      it "applies coverage threshold override" do
        config = Vitals::Config.new
        cli.instance_variable_set(:@options, { coverage_threshold: 70 })
        cli.send(:apply_option_overrides, config)
        expect(config.coverage[:threshold]).to eq(70)
      end
    end
  end
end

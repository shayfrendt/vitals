# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe Vitals::Orchestrator do
  let(:config) { Vitals::Config.new }

  describe "#initialize" do
    it "accepts a config and default vitals" do
      orchestrator = described_class.new(config: config)
      expect(orchestrator.config).to eq(config)
      expect(orchestrator.vitals_to_run).to eq([:complexity, :smells, :coverage])
    end

    it "allows specifying which vitals to run" do
      orchestrator = described_class.new(config: config, vitals: [:complexity])
      expect(orchestrator.vitals_to_run).to eq([:complexity])
    end
  end

  describe "#run" do
    let(:temp_dir) { Dir.mktmpdir }
    let(:simple_file) { File.join(temp_dir, "simple.rb") }

    before do
      File.write(simple_file, <<~RUBY)
        class Simple
          def hello
            "world"
          end
        end
      RUBY
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "running all vitals" do
      it "returns a HealthReport" do
        orchestrator = described_class.new(config: config, vitals: [:complexity, :smells])
        report = orchestrator.run(path: temp_dir)

        expect(report).to be_a(Vitals::HealthReport)
      end

      it "collects results from all vitals" do
        orchestrator = described_class.new(config: config, vitals: [:complexity, :smells])
        report = orchestrator.run(path: temp_dir)

        expect(report.vital_results.length).to eq(2)
        expect(report.vital_results.map(&:vital)).to contain_exactly(:complexity, :smells)
      end

      it "calculates overall score" do
        orchestrator = described_class.new(config: config, vitals: [:complexity, :smells])
        report = orchestrator.run(path: temp_dir)

        expect(report.overall_score).to be_between(0, 100)
      end
    end

    context "running specific vitals" do
      it "runs only complexity vital when specified" do
        orchestrator = described_class.new(config: config, vitals: [:complexity])
        report = orchestrator.run(path: temp_dir)

        expect(report.vital_results.length).to eq(1)
        expect(report.vital_results.first.vital).to eq(:complexity)
      end

      it "runs only smells vital when specified" do
        orchestrator = described_class.new(config: config, vitals: [:smells])
        report = orchestrator.run(path: temp_dir)

        expect(report.vital_results.length).to eq(1)
        expect(report.vital_results.first.vital).to eq(:smells)
      end
    end

    context "when a vital fails" do
      it "skips the failing vital and continues" do
        # Coverage will fail because there's no coverage data
        orchestrator = described_class.new(config: config, vitals: [:complexity, :coverage])

        # Should not raise an error
        expect {
          report = orchestrator.run(path: temp_dir)
          # Only complexity should succeed
          expect(report.vital_results.length).to eq(1)
          expect(report.vital_results.first.vital).to eq(:complexity)
        }.not_to raise_error
      end
    end

    context "with invalid vital name" do
      it "raises an error" do
        orchestrator = described_class.new(config: config, vitals: [:invalid])

        expect {
          orchestrator.run(path: temp_dir)
        }.to raise_error(Vitals::Error, /Unknown vital/)
      end
    end
  end
end
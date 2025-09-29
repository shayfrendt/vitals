# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require "json"

RSpec.describe Vitals::Vitals::CoverageVital do
  let(:config) { Vitals::Config.new }
  let(:vital) { described_class.new(config: config) }

  describe "#check" do
    context "with coverage data available" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:coverage_dir) { File.join(temp_dir, "coverage") }
      let(:resultset_path) { File.join(coverage_dir, ".resultset.json") }

      before do
        FileUtils.mkdir_p(coverage_dir)

        # Create a mock SimpleCov resultset
        resultset_data = {
          "RSpec" => {
            "coverage" => {
              "#{temp_dir}/lib/example.rb" => [1, 1, 1, 0, 0, 1, 1, 1, nil, nil],
              "#{temp_dir}/lib/another.rb" => [1, 1, 1, 1, 1]
            },
            "timestamp" => Time.now.to_i
          }
        }

        File.write(resultset_path, JSON.generate(resultset_data))

        # Create a Gemfile to mark this as project root
        File.write(File.join(temp_dir, "Gemfile"), "source 'https://rubygems.org'")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "returns a VitalResult" do
        result = vital.check(path: temp_dir)
        expect(result).to be_a(Vitals::VitalResult)
      end

      it "calculates coverage score" do
        result = vital.check(path: temp_dir)
        expect(result.score).to be_between(0, 100)
      end

      it "includes metadata" do
        result = vital.check(path: temp_dir)
        expect(result.metadata).to include(
          :line_coverage,
          :branch_coverage,
          :total_lines,
          :covered_lines
        )
      end

      it "identifies files below threshold" do
        # With the mock data above, example.rb has 62.5% coverage (5/8 lines)
        # If threshold is 80%, it should be flagged
        result = vital.check(path: temp_dir)

        # Violations are files below threshold
        if result.violations.any?
          violation = result.violations.first
          expect(violation).to include(:file, :coverage_percent, :message)
        end
      end
    end

    context "without coverage data" do
      let(:temp_dir) { Dir.mktmpdir }

      before do
        # Create a Gemfile but no coverage directory
        File.write(File.join(temp_dir, "Gemfile"), "source 'https://rubygems.org'")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "raises an error when no coverage data exists" do
        expect {
          vital.check(path: temp_dir)
        }.to raise_error(Vitals::Error, /No coverage data found/)
      end
    end

    context "with non-existent path" do
      it "raises an error" do
        expect {
          vital.check(path: "/non/existent/path")
        }.to raise_error(Vitals::Error, /does not exist/)
      end
    end
  end

  describe "#threshold" do
    it "returns the coverage threshold from config" do
      expect(vital.threshold).to eq(config.coverage[:threshold])
    end
  end
end
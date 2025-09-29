# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe Vitals::Vitals::ComplexityVital do
  let(:config) { Vitals::Config.new }
  let(:vital) { described_class.new(config: config) }

  describe "#check" do
    context "with a simple Ruby file" do
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

      it "returns a VitalResult" do
        result = vital.check(path: simple_file)
        expect(result).to be_a(Vitals::VitalResult)
      end

      it "returns a high score for simple code" do
        result = vital.check(path: simple_file)
        expect(result.score).to be >= 90
      end

      it "has no violations for simple code" do
        result = vital.check(path: simple_file)
        expect(result.violations).to be_empty
      end

      it "includes metadata" do
        result = vital.check(path: simple_file)
        expect(result.metadata).to include(
          :average_complexity,
          :methods_over_threshold,
          :worst_offenders,
          :total_methods_analyzed
        )
      end
    end

    context "with a complex Ruby file" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:complex_file) { File.join(temp_dir, "complex.rb") }

      before do
        # Create a file with high cyclomatic complexity
        File.write(complex_file, <<~RUBY)
          class Complex
            def complex_method(x)
              if x > 10
                if x > 20
                  if x > 30
                    if x > 40
                      if x > 50
                        if x > 60
                          if x > 70
                            if x > 80
                              if x > 90
                                "very high"
                              else
                                "high"
                              end
                            else
                              "medium-high"
                            end
                          else
                            "medium"
                          end
                        else
                          "medium-low"
                        end
                      else
                        "low-medium"
                      end
                    else
                      "low"
                    end
                  else
                    "very low"
                  end
                else
                  "minimal"
                end
              else
                "none"
              end
            end
          end
        RUBY
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "detects complexity violations" do
        result = vital.check(path: complex_file)
        expect(result.violations.length).to be > 0
      end

      it "returns a lower score for complex code" do
        result = vital.check(path: complex_file)
        expect(result.score).to be < 100
      end

      it "includes violation details" do
        result = vital.check(path: complex_file)
        violation = result.violations.first

        expect(violation).to include(:file, :line, :message)
      end
    end

    context "with a directory" do
      let(:temp_dir) { Dir.mktmpdir }

      before do
        File.write(File.join(temp_dir, "file1.rb"), "class A; def x; 1; end; end")
        File.write(File.join(temp_dir, "file2.rb"), "class B; def y; 2; end; end")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "analyzes all Ruby files in the directory" do
        result = vital.check(path: temp_dir)
        expect(result).to be_a(Vitals::VitalResult)
        expect(result.metadata[:total_methods_analyzed]).to be >= 0
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
    it "returns the complexity threshold from config" do
      expect(vital.threshold).to eq(config.complexity[:threshold])
    end
  end
end
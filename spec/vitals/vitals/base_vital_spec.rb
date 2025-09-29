# frozen_string_literal: true

RSpec.describe Vitals::Vitals::BaseVital do
  let(:config) { Vitals::Config.new }

  # Create a concrete implementation for testing
  let(:test_vital_class) do
    Class.new(described_class) do
      def check(path:)
        create_result(score: 85, violations: [], metadata: {})
      end
    end
  end

  describe "#initialize" do
    it "requires a config" do
      vital = test_vital_class.new(config: config)

      expect(vital.config).to eq(config)
    end
  end

  describe "#check" do
    it "raises NotImplementedError in base class" do
      base_vital = described_class.new(config: config)

      expect { base_vital.check(path: ".") }.to raise_error(NotImplementedError)
    end

    it "can be implemented by subclasses" do
      vital = test_vital_class.new(config: config)
      result = vital.check(path: ".")

      expect(result).to be_a(Vitals::VitalResult)
      expect(result.score).to eq(85)
    end
  end

  describe "#threshold" do
    it "returns complexity threshold for complexity vital" do
      vital = test_vital_class.new(config: config)
      allow(vital).to receive(:name).and_return(:complexity)

      expect(vital.threshold).to eq(10)
    end

    it "returns smells threshold for smells vital" do
      vital = test_vital_class.new(config: config)
      allow(vital).to receive(:name).and_return(:smells)

      expect(vital.threshold).to eq(80)
    end

    it "returns coverage threshold for coverage vital" do
      vital = test_vital_class.new(config: config)
      allow(vital).to receive(:name).and_return(:coverage)

      expect(vital.threshold).to eq(80)
    end
  end

  describe "#create_result" do
    it "creates a VitalResult with the vital's name" do
      vital = test_vital_class.new(config: config)
      result = vital.send(:create_result, score: 90, violations: [], metadata: {})

      expect(result).to be_a(Vitals::VitalResult)
      expect(result.score).to eq(90)
    end
  end
end
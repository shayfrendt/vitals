# frozen_string_literal: true

RSpec.describe Vitals::VitalResult do
  describe "#initialize" do
    it "creates a result with required attributes" do
      result = described_class.new(vital: :complexity, score: 85)

      expect(result.vital).to eq(:complexity)
      expect(result.score).to eq(85)
      expect(result.violations).to eq([])
      expect(result.metadata).to eq({})
      expect(result.timestamp).to be_a(Time)
    end

    it "accepts optional violations and metadata" do
      violations = ["Method too complex"]
      metadata = { average: 5.2 }

      result = described_class.new(
        vital: :complexity,
        score: 85,
        violations: violations,
        metadata: metadata
      )

      expect(result.violations).to eq(violations)
      expect(result.metadata).to eq(metadata)
    end
  end

  describe "#healthy?" do
    it "returns true when score meets threshold" do
      result = described_class.new(vital: :complexity, score: 85)

      expect(result.healthy?(threshold: 80)).to be true
    end

    it "returns true when score equals threshold" do
      result = described_class.new(vital: :complexity, score: 80)

      expect(result.healthy?(threshold: 80)).to be true
    end

    it "returns false when score is below threshold" do
      result = described_class.new(vital: :complexity, score: 75)

      expect(result.healthy?(threshold: 80)).to be false
    end
  end

  describe "#to_h" do
    it "converts result to hash" do
      result = described_class.new(
        vital: :complexity,
        score: 85,
        violations: ["test"],
        metadata: { average: 5.2 }
      )

      hash = result.to_h

      expect(hash[:vital]).to eq(:complexity)
      expect(hash[:score]).to eq(85)
      expect(hash[:violations_count]).to eq(1)
      expect(hash[:violations]).to eq(["test"])
      expect(hash[:metadata]).to eq({ average: 5.2 })
      expect(hash[:timestamp]).to be_a(String)
    end
  end
end
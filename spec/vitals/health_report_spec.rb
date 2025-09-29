# frozen_string_literal: true

RSpec.describe Vitals::HealthReport do
  let(:config) { Vitals::Config.new }

  let(:complexity_result) do
    Vitals::VitalResult.new(vital: :complexity, score: 90, violations: [])
  end

  let(:smells_result) do
    Vitals::VitalResult.new(vital: :smells, score: 75, violations: ["TooManyMethods"])
  end

  let(:coverage_result) do
    Vitals::VitalResult.new(vital: :coverage, score: 85, violations: [])
  end

  describe "#initialize" do
    it "calculates overall score from vital results" do
      report = described_class.new(
        vital_results: [complexity_result, smells_result, coverage_result],
        config: config
      )

      # (90 * 0.4) + (75 * 0.3) + (85 * 0.3) = 36 + 22.5 + 25.5 = 84
      expect(report.overall_score).to eq(84.0)
    end

    it "handles empty vital results" do
      report = described_class.new(vital_results: [], config: config)

      expect(report.overall_score).to eq(0)
    end
  end

  describe "#health_status" do
    it "returns :excellent for score 90-100" do
      report = described_class.new(
        vital_results: [
          Vitals::VitalResult.new(vital: :complexity, score: 95),
          Vitals::VitalResult.new(vital: :smells, score: 95),
          Vitals::VitalResult.new(vital: :coverage, score: 95)
        ],
        config: config
      )

      expect(report.health_status).to eq(:excellent)
    end

    it "returns :good for score 75-89" do
      report = described_class.new(
        vital_results: [complexity_result, smells_result, coverage_result],
        config: config
      )

      expect(report.health_status).to eq(:good)
    end

    it "returns :needs_improvement for score 60-74" do
      report = described_class.new(
        vital_results: [
          Vitals::VitalResult.new(vital: :complexity, score: 70),
          Vitals::VitalResult.new(vital: :smells, score: 65),
          Vitals::VitalResult.new(vital: :coverage, score: 65)
        ],
        config: config
      )

      expect(report.health_status).to eq(:needs_improvement)
    end

    it "returns :high_risk for score below 60" do
      report = described_class.new(
        vital_results: [
          Vitals::VitalResult.new(vital: :complexity, score: 50),
          Vitals::VitalResult.new(vital: :smells, score: 50),
          Vitals::VitalResult.new(vital: :coverage, score: 50)
        ],
        config: config
      )

      expect(report.health_status).to eq(:high_risk)
    end
  end

  describe "#recommendations" do
    it "generates recommendations for unhealthy vitals" do
      report = described_class.new(
        vital_results: [smells_result],
        config: config
      )

      recommendations = report.recommendations

      expect(recommendations).to include(match(/Smells vital is below threshold/))
      expect(recommendations).to include(match(/Address 1 smells violations/))
    end

    it "returns empty array when all vitals are healthy" do
      report = described_class.new(
        vital_results: [
          Vitals::VitalResult.new(vital: :complexity, score: 95, violations: []),
          Vitals::VitalResult.new(vital: :smells, score: 90, violations: []),
          Vitals::VitalResult.new(vital: :coverage, score: 90, violations: [])
        ],
        config: config
      )

      recommendations = report.recommendations

      expect(recommendations).to be_empty
    end
  end

  describe "#to_h" do
    it "converts report to hash" do
      report = described_class.new(
        vital_results: [complexity_result],
        config: config
      )

      hash = report.to_h

      expect(hash[:overall_score]).to be_a(Numeric)
      expect(hash[:health_status]).to be_a(Symbol)
      expect(hash[:vitals]).to be_an(Array)
      expect(hash[:recommendations]).to be_an(Array)
      expect(hash[:generated_at]).to be_a(String)
    end
  end
end
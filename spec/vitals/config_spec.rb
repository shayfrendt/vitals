# frozen_string_literal: true

RSpec.describe Vitals::Config do
  describe "#initialize" do
    it "loads default configuration" do
      config = described_class.new

      expect(config.complexity[:threshold]).to eq(90)
      expect(config.smells[:threshold]).to eq(80)
      expect(config.coverage[:threshold]).to eq(90)
    end

    it "applies overrides to default configuration" do
      config = described_class.new(overrides: { complexity: { threshold: 15 } })

      expect(config.complexity[:threshold]).to eq(15)
      expect(config.smells[:threshold]).to eq(80) # unchanged
    end

    it "deep merges overrides" do
      config = described_class.new(
        overrides: {
          complexity: { threshold: 15 },
          output: { format: :json }
        }
      )

      expect(config.complexity[:threshold]).to eq(15)
      expect(config.complexity[:exclude]).to eq([])
      expect(config.output[:format]).to eq(:json)
      expect(config.output[:color]).to eq(true)
    end
  end

  describe "accessor methods" do
    it "provides access to complexity config" do
      config = described_class.new

      expect(config.complexity).to be_a(Hash)
      expect(config.complexity).to have_key(:threshold)
    end

    it "provides access to smells config" do
      config = described_class.new

      expect(config.smells).to be_a(Hash)
      expect(config.smells).to have_key(:threshold)
    end

    it "provides access to coverage config" do
      config = described_class.new

      expect(config.coverage).to be_a(Hash)
      expect(config.coverage).to have_key(:threshold)
    end

    it "provides access to output config" do
      config = described_class.new

      expect(config.output).to be_a(Hash)
      expect(config.output).to have_key(:format)
    end
  end
end
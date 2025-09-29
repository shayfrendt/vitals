# frozen_string_literal: true

RSpec.describe Vitals do
  it "has a version number" do
    expect(Vitals::VERSION).not_to be nil
  end

  it "loads all components" do
    expect(Vitals::Config).to be_a(Class)
    expect(Vitals::VitalResult).to be_a(Class)
    expect(Vitals::HealthReport).to be_a(Class)
    expect(Vitals::Vitals::BaseVital).to be_a(Class)
  end
end

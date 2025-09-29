# frozen_string_literal: true

module Vitals
  class HealthReport
    WEIGHTS = {
      complexity: 0.40,
      smells: 0.30,
      coverage: 0.30
    }.freeze

    attr_reader :overall_score, :vital_results, :config

    def initialize(vital_results:, config:)
      @vital_results = vital_results
      @config = config
      @overall_score = calculate_overall_score
    end

    def health_status
      case overall_score
      when 90..100 then :excellent
      when 75..89  then :good
      when 60..74  then :needs_improvement
      else              :high_risk
      end
    end

    def recommendations
      vital_results.flat_map do |result|
        generate_recommendations_for(result)
      end
    end

    def to_h
      {
        overall_score: overall_score.round(1),
        health_status: health_status,
        vitals: vital_results.map(&:to_h),
        recommendations: recommendations,
        generated_at: Time.now.strftime("%Y-%m-%dT%H:%M:%S%z")
      }
    end

    private

    def calculate_overall_score
      return 0 if vital_results.empty?

      weighted_sum = vital_results.sum do |result|
        weight = WEIGHTS[result.vital] || 0
        result.score * weight
      end

      weighted_sum.round(1)
    end

    def generate_recommendations_for(result)
      recommendations = []

      unless result.healthy?(threshold: threshold_for(result.vital))
        recommendations << "#{result.vital.capitalize} vital is below threshold (#{result.score} < #{threshold_for(result.vital)})"
      end

      if result.violations.any?
        recommendations << "Address #{result.violations.length} #{result.vital} violations"
      end

      recommendations
    end

    def threshold_for(vital)
      case vital
      when :complexity
        config.complexity[:threshold]
      when :smells
        config.smells[:threshold]
      when :coverage
        config.coverage[:threshold]
      else
        0
      end
    end
  end
end
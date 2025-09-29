# frozen_string_literal: true

module Vitals
  class VitalResult
    attr_reader :vital, :score, :violations, :metadata, :timestamp

    def initialize(vital:, score:, violations: [], metadata: {})
      @vital = vital
      @score = score
      @violations = violations
      @metadata = metadata
      @timestamp = Time.now
    end

    def healthy?(threshold:)
      score >= threshold
    end

    def to_h
      {
        vital: vital,
        score: score,
        violations_count: violations.length,
        violations: violations,
        metadata: metadata,
        timestamp: timestamp.strftime("%Y-%m-%dT%H:%M:%S%z")
      }
    end
  end
end
# frozen_string_literal: true

module Vitals
  module Vitals
    class BaseVital
      attr_reader :name, :config

      def initialize(config:)
        @config = config
        class_name = self.class.name || ""
        @name = class_name.split("::").last.to_s.gsub("Vital", "").downcase.to_sym
      end

      # Must be implemented by subclasses
      # Returns a VitalResult object
      def check(path:)
        raise NotImplementedError, "#{self.class} must implement #check"
      end

      def threshold
        case name
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

      protected

      def create_result(score:, violations: [], metadata: {})
        VitalResult.new(
          vital: name,
          score: score,
          violations: violations,
          metadata: metadata
        )
      end
    end
  end
end
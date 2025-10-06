# frozen_string_literal: true

module Vitals
  module Reporters
    class BaseReporter
      attr_reader :report, :config

      def initialize(report:, config:)
        @report = report
        @config = config
      end

      # Must be implemented by subclasses
      def render
        raise NotImplementedError, "#{self.class} must implement #render"
      end

      protected

      def threshold_for_vital(vital)
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
end
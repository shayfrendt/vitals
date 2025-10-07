# frozen_string_literal: true

module Vitals
  # Helper class to run individual vital checks
  class CLIVitalRunner
      attr_reader :vital_class, :config, :path

      def initialize(vital_class:, config:, path:)
        @vital_class = vital_class
        @config = config
        @path = path
      end

      def execute
        vital = vital_class.new(config: config)
        vital.check(path: path)
      end

      def reporter_for(result)
        CLIReporterFactory.for_result(result: result, config: config)
      end

      def exit_status_for(result)
        vital = vital_class.new(config: config)
        result.healthy?(threshold: vital.threshold) ? 0 : 1
      end
  end
end

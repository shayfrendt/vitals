# frozen_string_literal: true

module Vitals
  # Helper class to format and display output based on format option
  class CLIOutputFormatter
      attr_reader :format, :path, :reporter

      def initialize(format:, path:, reporter:)
        @format = format
        @path = path
        @reporter = reporter
      end

      def display_check
        if cli_format?
          CLIDisplayHelper.check_header(path)
          puts "\n#{reporter.render_summary}"
        else
          puts reporter.render
        end
      end

      def display_report
        if cli_format?
          CLIDisplayHelper.report_header(path)
          puts "\n#{reporter.render}"
        elsif html_format?
          warn "HTML format not yet implemented (Phase 5)"
        else
          puts reporter.render
        end
      end

      def display_vital(result, header)
        if cli_format?
          CLIDisplayHelper.vital_header(path, header)
          CLIDisplayHelper.result_summary(result)
          CLIDisplayHelper.violations_list(result.violations)
          CLIDisplayHelper.completion_message if result.violations.any?
        else
          puts reporter.render
        end
      end

      private

      def cli_format?
        format == "cli"
      end

      def html_format?
        format == "html"
      end
  end
end

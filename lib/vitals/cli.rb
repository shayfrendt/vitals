# frozen_string_literal: true

require "thor"
require "json"
require_relative "../vitals"
require_relative "cli/config_manager"
require_relative "cli/display_helper"
require_relative "cli/threshold_helper"
require_relative "cli/reporter_factory"
require_relative "cli/vital_runner"
require_relative "cli/output_formatter"

module Vitals
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class_option :config, type: :string, aliases: "-c", desc: "Path to configuration file"
    class_option :format, type: :string, default: "cli", enum: %w[cli json html], desc: "Output format"

    desc "check [PATH]", "Run all vitals checks on the codebase"
    option :complexity_threshold, type: :numeric, desc: "Override complexity threshold"
    option :smells_threshold, type: :numeric, desc: "Override smells threshold"
    option :coverage_threshold, type: :numeric, desc: "Override coverage threshold"
    def check(path = ".")
      config = config_manager.load_with_overrides
      health_report = run_orchestrator(config, path)
      reporter = CLIReporterFactory.create(format: options[:format], report: health_report, config: config)
      formatter = CLIOutputFormatter.new(format: options[:format], path: path, reporter: reporter)

      formatter.display_check
      exit CLIThresholdHelper.exit_code_for(health_report, config)
    rescue StandardError => e
      handle_error(e)
    end

    desc "complexity [PATH]", "Check code complexity"
    def complexity(path = ".")
      run_single_vital(Vitals::ComplexityVital, path, "🧠 Checking complexity in")
    end

    desc "smells [PATH]", "Check code smells"
    def smells(path = ".")
      run_single_vital(Vitals::SmellsVital, path, "👃 Checking code smells in")
    end

    desc "coverage [PATH]", "Check test coverage"
    def coverage(path = ".")
      run_single_vital(Vitals::CoverageVital, path, "🛡️  Checking test coverage in")
    end

    desc "report [PATH]", "Generate full health report"
    def report(path = ".")
      config = config_manager.load_with_overrides
      health_report = run_orchestrator(config, path)
      reporter = CLIReporterFactory.create(format: options[:format], report: health_report, config: config)
      formatter = CLIOutputFormatter.new(format: options[:format], path: path, reporter: reporter)

      formatter.display_report
      exit 0
    rescue StandardError => e
      handle_error(e)
    end

    desc "version", "Show version"
    def version
      puts "Vitals version #{VERSION}"
    end

    private

    def config_manager
      @config_manager ||= CLIConfigManager.new(options)
    end

    def run_single_vital(vital_class, path, header)
      config = config_manager.load_with_overrides
      runner = CLIVitalRunner.new(vital_class: vital_class, config: config, path: path)
      result = runner.execute
      reporter = runner.reporter_for(result)
      formatter = CLIOutputFormatter.new(format: options[:format], path: path, reporter: reporter)

      formatter.display_vital(result, header)
      exit runner.exit_status_for(result)
    rescue StandardError => e
      handle_error(e)
    end

    def run_orchestrator(config, path)
      orchestrator = Orchestrator.new(config: config)
      orchestrator.run(path: path)
    end

    def handle_error(error)
      warn "❌ Error: #{error.message}"
      warn error.backtrace.join("\n") if ENV["DEBUG"]
      exit 2
    end
  end
end
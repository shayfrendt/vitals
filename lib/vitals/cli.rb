# frozen_string_literal: true

require "thor"
require "json"
require_relative "../vitals"

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
      config = load_config
      apply_option_overrides(config)

      health_report = run_orchestrator(config, path)
      reporter = create_reporter(health_report, config)

      display_check_output(path, reporter)
      exit determine_exit_code(health_report, config)
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
      config = load_config
      apply_option_overrides(config)

      health_report = run_orchestrator(config, path)
      reporter = create_reporter(health_report, config)

      display_report_output(path, reporter)
      exit 0
    rescue StandardError => e
      handle_error(e)
    end

    desc "version", "Show version"
    def version
      puts "Vitals version #{VERSION}"
    end

    private

    def load_config
      config_path = options[:config]
      if config_path && !File.exist?(config_path)
        warn "⚠️  Config file not found: #{config_path}"
      end
      Config.new(config_path: config_path)
    end

    def apply_option_overrides(config)
      if options[:complexity_threshold]
        config.complexity[:threshold] = options[:complexity_threshold]
      end

      if options[:smells_threshold]
        config.smells[:threshold] = options[:smells_threshold]
      end

      if options[:coverage_threshold]
        config.coverage[:threshold] = options[:coverage_threshold]
      end
    end

    def run_single_vital(vital_class, path, header)
      config = load_config
      apply_option_overrides(config)

      vital = vital_class.new(config: config)
      result = vital.check(path: path)

      health_report = HealthReport.new(vital_results: [result], config: config)
      reporter = create_reporter(health_report, config)

      if options[:format] == "cli"
        puts "#{header}: #{File.expand_path(path)}"
        puts "━" * 50
        display_result(result)
      else
        puts reporter.render
      end

      exit result.healthy?(threshold: vital.threshold) ? 0 : 1
    rescue StandardError => e
      handle_error(e)
    end

    def display_result(result)
      threshold = result.score >= 80 ? 80 : 0
      status = result.healthy?(threshold: threshold) ? "🟢 HEALTHY" : "🔴 NEEDS ATTENTION"

      puts "\n📊 Result:"
      puts "  Score: #{result.score}/100"
      puts "  Status: #{status}"
      puts "  Violations: #{result.violations.length}"

      return unless result.violations.any?

      display_violations(result.violations)
      puts "\n✓ Analysis complete"
    end

    def display_violations(violations)
      if violations.length <= 10
        puts "\n⚠️  Top violations:"
      else
        puts "\n⚠️  #{violations.length} violations found (showing first 10):"
      end

      violations.take(10).each do |violation|
        puts "  • #{violation[:file]}:#{violation[:line]} - #{violation[:message] || violation[:type]}"
      end
    end

    def create_reporter(report, config)
      case options[:format]
      when "json"
        Reporters::JsonReporter.new(report: report, config: config)
      when "html"
        # HTML reporter not implemented yet
        Reporters::CliReporter.new(report: report, config: config)
      else
        Reporters::CliReporter.new(report: report, config: config)
      end
    end

    def threshold_for_vital(vital, config)
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

    def run_orchestrator(config, path)
      orchestrator = Orchestrator.new(config: config)
      orchestrator.run(path: path)
    end

    def display_check_output(path, reporter)
      if options[:format] == "cli"
        puts "🏥 Running vitals check on: #{File.expand_path(path)}"
        puts "━" * 50
        puts "\n#{reporter.render_summary}"
      else
        puts reporter.render
      end
    end

    def display_report_output(path, reporter)
      if options[:format] == "cli"
        puts "📊 Generating health report for: #{File.expand_path(path)}"
        puts "━" * 50
        puts "\n#{reporter.render}"
      elsif options[:format] == "html"
        warn "HTML format not yet implemented (Phase 5)"
      else
        puts reporter.render
      end
    end

    def determine_exit_code(health_report, config)
      all_healthy = health_report.vital_results.all? do |result|
        threshold = threshold_for_vital(result.vital, config)
        result.healthy?(threshold: threshold)
      end
      all_healthy ? 0 : 1
    end

    def handle_error(error)
      warn "❌ Error: #{error.message}"
      warn error.backtrace.join("\n") if ENV["DEBUG"]
      exit 2
    end
  end
end
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

      puts "🏥 Running vitals check on: #{File.expand_path(path)}"
      puts "━" * 50

      orchestrator = Orchestrator.new(config: config)
      report = orchestrator.run(path: path)

      # Display summary
      puts "\n" + "━" * 50
      puts "📊 HEALTH REPORT"
      puts "━" * 50

      puts "\n Overall Score: #{report.overall_score}/100 (#{report.health_status.to_s.upcase.tr('_', ' ')})"

      all_healthy = true
      report.vital_results.each do |result|
        threshold = threshold_for_vital(result.vital, config)
        status = result.healthy?(threshold: threshold) ? "🟢 PASS" : "🔴 FAIL"

        puts "\n#{result.vital.to_s.capitalize}: #{status}"
        puts "  Score: #{result.score}/100 (threshold: #{threshold})"
        puts "  Violations: #{result.violations.length}"

        all_healthy = false unless result.healthy?(threshold: threshold)
      end

      if report.recommendations.any?
        puts "\n💡 Recommendations:"
        report.recommendations.each do |rec|
          puts "  • #{rec}"
        end
      end

      puts "\n" + "━" * 50
      exit all_healthy ? 0 : 1
    rescue StandardError => e
      handle_error(e)
    end

    desc "complexity [PATH]", "Check code complexity"
    def complexity(path = ".")
      config = load_config
      apply_option_overrides(config)

      puts "🧠 Checking complexity in: #{File.expand_path(path)}"
      puts "━" * 50

      vital = Vitals::ComplexityVital.new(config: config)
      result = vital.check(path: path)

      display_result(result, config)

      exit result.healthy?(threshold: vital.threshold) ? 0 : 1
    rescue StandardError => e
      handle_error(e)
    end

    desc "smells [PATH]", "Check code smells"
    def smells(path = ".")
      config = load_config
      apply_option_overrides(config)

      puts "👃 Checking code smells in: #{File.expand_path(path)}"
      puts "━" * 50

      vital = Vitals::SmellsVital.new(config: config)
      result = vital.check(path: path)

      display_result(result, config)

      exit result.healthy?(threshold: vital.threshold) ? 0 : 1
    rescue StandardError => e
      handle_error(e)
    end

    desc "coverage [PATH]", "Check test coverage"
    def coverage(path = ".")
      config = load_config
      apply_option_overrides(config)

      puts "🛡️  Checking test coverage in: #{File.expand_path(path)}"
      puts "━" * 50

      vital = Vitals::CoverageVital.new(config: config)
      result = vital.check(path: path)

      display_result(result, config)

      exit result.healthy?(threshold: vital.threshold) ? 0 : 1
    rescue StandardError => e
      handle_error(e)
    end

    desc "report [PATH]", "Generate full health report"
    def report(path = ".")
      config = load_config
      apply_option_overrides(config)

      orchestrator = Orchestrator.new(config: config)
      report = orchestrator.run(path: path)

      # Output in requested format
      case options[:format]
      when "json"
        puts JSON.pretty_generate(report.to_h)
      when "html"
        warn "📊 Generating health report for: #{File.expand_path(path)}"
        warn "HTML format not yet implemented (Phase 5)"
      else
        puts "📊 Generating health report for: #{File.expand_path(path)}"
        puts "━" * 50
        display_cli_report(report, config)
      end

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

    def display_result(result, config)
      puts "\n📊 Result:"
      puts "  Score: #{result.score}/100"
      puts "  Status: #{result.healthy?(threshold: result.score >= 80 ? 80 : 0) ? '🟢 HEALTHY' : '🔴 NEEDS ATTENTION'}"
      puts "  Violations: #{result.violations.length}"

      if result.violations.any? && result.violations.length <= 10
        puts "\n⚠️  Top violations:"
        result.violations.take(10).each do |violation|
          puts "  • #{violation[:file]}:#{violation[:line]} - #{violation[:message] || violation[:type]}"
        end
      elsif result.violations.length > 10
        puts "\n⚠️  #{result.violations.length} violations found (showing first 10):"
        result.violations.take(10).each do |violation|
          puts "  • #{violation[:file]}:#{violation[:line]} - #{violation[:message] || violation[:type]}"
        end
      end

      puts "\n✓ Analysis complete"
    end

    def display_cli_report(report, config)
      puts "\n╔═══════════════════════════════════════════╗"
      puts "║   CODEBASE HEALTH REPORT                  ║"
      puts "╠═══════════════════════════════════════════╣"
      puts "║   Overall Score: #{report.overall_score}/100"
      puts "║   Status: #{status_emoji(report.health_status)} #{report.health_status.to_s.upcase.tr('_', ' ')}"
      puts "╠═══════════════════════════════════════════╣"

      report.vital_results.each do |result|
        threshold = threshold_for_vital(result.vital, config)
        status = result.healthy?(threshold: threshold) ? "🟢" : "🔴"
        puts "║   #{result.vital.to_s.capitalize} Vital: #{status} #{result.score}/100"
      end

      puts "╠═══════════════════════════════════════════╣"

      if report.recommendations.any?
        puts "║   Recommendations:"
        report.recommendations.each do |rec|
          puts "║   • #{rec}"
        end
      else
        puts "║   ✓ All vitals are healthy!"
      end

      puts "╚═══════════════════════════════════════════╝"
    end

    def status_emoji(status)
      case status
      when :excellent then "🟢"
      when :good then "🟢"
      when :needs_improvement then "🟡"
      when :high_risk then "🔴"
      else "⚪"
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

    def handle_error(error)
      warn "❌ Error: #{error.message}"
      warn error.backtrace.join("\n") if ENV["DEBUG"]
      exit 2
    end
  end
end
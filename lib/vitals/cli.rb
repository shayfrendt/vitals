# frozen_string_literal: true

require "thor"
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

      results = {}

      # Run complexity check
      puts "\n🧠 Checking complexity..."
      complexity_vital = Vitals::ComplexityVital.new(config: config)
      results[:complexity] = complexity_vital.check(path: path)

      # Run smells check
      puts "\n👃 Checking code smells..."
      smells_vital = Vitals::SmellsVital.new(config: config)
      results[:smells] = smells_vital.check(path: path)

      # Run coverage check (may fail if no coverage data)
      puts "\n🛡️  Checking test coverage..."
      begin
        coverage_vital = Vitals::CoverageVital.new(config: config)
        results[:coverage] = coverage_vital.check(path: path)
      rescue Error => e
        puts "  ⚠️  #{e.message}"
        results[:coverage] = nil
      end

      # Display summary
      puts "\n" + "━" * 50
      puts "📊 SUMMARY"
      puts "━" * 50

      all_healthy = true
      results.each do |vital_name, result|
        next if result.nil?

        vital = case vital_name
                when :complexity then complexity_vital
                when :smells then smells_vital
                when :coverage then coverage_vital
                end

        status = result.healthy?(threshold: vital.threshold) ? "🟢 PASS" : "🔴 FAIL"
        puts "\n#{vital_name.to_s.capitalize}: #{status}"
        puts "  Score: #{result.score}/100 (threshold: #{vital.threshold})"
        puts "  Violations: #{result.violations.length}"

        all_healthy = false unless result.healthy?(threshold: vital.threshold)
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

      puts "📊 Generating health report for: #{File.expand_path(path)}"
      puts "━" * 50
      puts "\n✓ Report generation CLI working!"
      puts "(Full report coming in Phase 5)"

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

    def handle_error(error)
      warn "❌ Error: #{error.message}"
      warn error.backtrace.join("\n") if ENV["DEBUG"]
      exit 2
    end
  end
end
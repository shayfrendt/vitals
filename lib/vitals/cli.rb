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

      # For now, just show that the CLI is working
      # We'll implement the actual checks in Phase 3
      puts "\n✓ CLI interface working!"
      puts "\nConfiguration loaded:"
      puts "  Complexity threshold: #{config.complexity[:threshold]}"
      puts "  Smells threshold: #{config.smells[:threshold]}"
      puts "  Coverage threshold: #{config.coverage[:threshold]}"
      puts "  Format: #{options[:format]}"

      exit 0
    rescue StandardError => e
      handle_error(e)
    end

    desc "complexity [PATH]", "Check code complexity"
    def complexity(path = ".")
      puts "🧠 Checking complexity in: #{File.expand_path(path)}"
      puts "\n✓ Complexity check CLI working!"
      puts "(Implementation coming in Phase 3)"
      exit 0
    rescue StandardError => e
      handle_error(e)
    end

    desc "smells [PATH]", "Check code smells"
    def smells(path = ".")
      puts "👃 Checking code smells in: #{File.expand_path(path)}"
      puts "\n✓ Smells check CLI working!"
      puts "(Implementation coming in Phase 3)"
      exit 0
    rescue StandardError => e
      handle_error(e)
    end

    desc "coverage [PATH]", "Check test coverage"
    def coverage(path = ".")
      puts "🛡️  Checking test coverage in: #{File.expand_path(path)}"
      puts "\n✓ Coverage check CLI working!"
      puts "(Implementation coming in Phase 3)"
      exit 0
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

    def handle_error(error)
      warn "❌ Error: #{error.message}"
      warn error.backtrace.join("\n") if ENV["DEBUG"]
      exit 2
    end
  end
end
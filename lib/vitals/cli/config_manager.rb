# frozen_string_literal: true

module Vitals
  # Helper class to manage configuration loading and overrides
  class CLIConfigManager
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def load_with_overrides
      config = load_base_config
      apply_overrides(config)
      config
    end

    private

    def load_base_config
      config_path = options[:config]
      if config_path && !File.exist?(config_path)
        warn "⚠️  Config file not found: #{config_path}"
      end
      Config.new(config_path: config_path)
    end

    def apply_overrides(config)
      override_threshold(config.complexity, :complexity_threshold)
      override_threshold(config.smells, :smells_threshold)
      override_threshold(config.coverage, :coverage_threshold)
    end

    def override_threshold(vital_config, option_key)
      return unless options[option_key]

      vital_config[:threshold] = options[option_key]
    end
  end
end

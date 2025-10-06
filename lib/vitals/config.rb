# frozen_string_literal: true

require "yaml"

module Vitals
  class Config
    DEFAULT_CONFIG = {
      complexity: {
        threshold: 90,
        exclude: []
      },
      smells: {
        threshold: 80,
        enabled_detectors: :all
      },
      coverage: {
        threshold: 90,
        require_branch_coverage: false
      },
      output: {
        format: :cli,
        color: true
      }
    }.freeze

    attr_reader :config

    def initialize(config_path: nil, overrides: {})
      @config = load_config(config_path)
      apply_overrides(overrides)
    end

    def complexity
      config[:complexity]
    end

    def smells
      config[:smells]
    end

    def coverage
      config[:coverage]
    end

    def output
      config[:output]
    end

    private

    def load_config(config_path)
      base = Marshal.load(Marshal.dump(DEFAULT_CONFIG))
      if config_path && File.exist?(config_path)
        file_config = YAML.load_file(config_path, symbolize_names: true)
        deep_merge(base, file_config)
      else
        base
      end
    end

    def apply_overrides(overrides)
      @config = deep_merge(@config, overrides)
    end

    def deep_merge(hash1, hash2)
      hash1.merge(hash2) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end
  end
end
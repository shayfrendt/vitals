# frozen_string_literal: true

require_relative "vitals/version"
require_relative "vitals/config"
require_relative "vitals/vital_result"
require_relative "vitals/health_report"
require_relative "vitals/vitals/base_vital"
require_relative "vitals/vitals/complexity_vital"
require_relative "vitals/vitals/smells_vital"
require_relative "vitals/vitals/coverage_vital"
require_relative "vitals/orchestrator"
require_relative "vitals/cli"

module Vitals
  class Error < StandardError; end
end

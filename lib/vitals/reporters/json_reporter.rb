# frozen_string_literal: true

require "json"

module Vitals
  module Reporters
    class JsonReporter < BaseReporter
      def render
        JSON.pretty_generate(report.to_h)
      end
    end
  end
end
# frozen_string_literal: true
module Kamigo
  # Provider owns its HTTP deadlines. No implicit tools, history, or paid calls.
  class Agent
    class LimitExceeded < StandardError; end
    def initialize(provider:, max_input_bytes: 16_384, max_output_bytes: 16_384)
      @provider, @input_limit, @output_limit = provider, max_input_bytes, max_output_bytes
    end
    def call(event:, context:)
      if defined?(ActiveRecord::Base) && ActiveRecord::Base.connected? && ActiveRecord::Base.connection.transaction_open?
        raise ArgumentError, "Agent calls must execute outside database transactions"
      end
      input = event.text.to_s
      raise LimitExceeded, "agent input too large" if input.bytesize > @input_limit
      output = @provider.call(input: input, context: context)
      raise TypeError, "agent must return text" unless output.is_a?(String)
      raise LimitExceeded, "agent output too large" if output.bytesize > @output_limit
      event.platform == "line" ? [{type: "text", text: output}] : [{text: output}]
    end
  end
end

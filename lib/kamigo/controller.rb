# frozen_string_literal: true
module Kamigo
  class Controller
    def initialize(renderer:)
      @renderer = renderer
    end
    attr_reader :event, :context
    def self.action(name, renderer:)
      raise ArgumentError, "action must be explicitly implemented" unless public_instance_methods(false).include?(name.to_sym)
      -> { new(renderer: renderer).bind_action(name) }
    end
    def bind_action(name)
      ->(event:, context:) do
        @event, @context = event, context
        public_send(name)
      end
    end
    def render(template, **assigns)
      @renderer.render(template: template, platform: event.platform, assigns: assigns)
    end
  end
end

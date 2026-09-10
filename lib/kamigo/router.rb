# frozen_string_literal: true
module Kamigo
  class Router
    Route = Data.define(:kind, :value, :target)
    def initialize(&block)
      @routes = []
      @fallback = nil
      instance_eval(&block) if block
      @commands, @events, @predicates = {}, {}, []
      @routes.each_with_index do |route, index|
        case route.kind
        when :command then @commands[route.value] ||= [index, route.target].freeze
        when :event then @events[route.value] ||= [index, route.target].freeze
        when :predicate then @predicates << [index, route].freeze
        end
      end
      @commands.freeze; @events.freeze; @predicates.freeze
      @routes.freeze
      freeze
    end

    def command(text, to:)
      raise ArgumentError, "command must not be empty" if text.to_s.empty?
      @routes << Route.new(kind: :command, value: text.to_s.dup.freeze, target: to.to_s.dup.freeze)
    end

    def on(type, to:)
      @routes << Route.new(kind: :event, value: type.to_sym, target: to.to_s.dup.freeze)
    end

    def match(to:, &predicate)
      raise ArgumentError, "predicate required" unless predicate
      @routes << Route.new(kind: :predicate, value: predicate, target: to.to_s.dup.freeze)
    end

    def fallback(to:)
      raise ArgumentError, "fallback already defined" if @fallback
      @fallback = to.to_s.dup.freeze
    end

    def resolve(event, context: Context.new)
      command = event.type == :message ? @commands[event.text] : nil
      kind = @events[event.type]
      candidate = command && kind ? (command[0] < kind[0] ? command : kind) : (command || kind)
      @predicates.each do |index, route|
        break if candidate && index > candidate[0]
        return route.target if route.value.call(event, context)
      end
      return candidate[1] if candidate
      @fallback
    end
  end
end

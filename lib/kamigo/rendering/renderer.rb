require 'action_view'
require 'action_dispatch'
require 'kamiflex'

module Kamigo
  module Rendering
    class InvalidTemplate < StandardError; end
    Platform = Data.define(:helper, :fallback)
    @platforms = {}
    @platform_lock = Mutex.new

    def self.register(format, helper: nil, fallback: nil, &block)
      format = format.to_sym
      fallback ||= block
      raise ArgumentError, 'platform format must be a simple identifier' unless format.to_s.match?(/\A[a-z][a-z0-9_]*\z/)
      raise ArgumentError, 'fallback must convert text to a message Hash' unless fallback.respond_to?(:call)
      @platform_lock.synchronize { @platforms[format] = Platform.new(helper: helper, fallback: fallback).freeze }
      format
    end

    def self.platform(format)
      @platform_lock.synchronize { @platforms[format.to_sym] }
    end

    # Templates emit structured messages, never JSON assembled through ERB interpolation.
    module Helpers
      def emit(message)
        raise InvalidTemplate, 'message must be a Hash' unless message.is_a?(Hash)
        @kamigo_messages << message
        nil
      end

      def text(value)
        emit(@kamigo_platform == :line ? { type: 'text', text: value.to_s } : { text: value.to_s })
      end

      def line_flex(&block)
        raise InvalidTemplate, 'line_flex requires LINE' unless @kamigo_platform == :line
        emit(Kamiflex.hash(&block))
      end

      def telegram_message(text:, buttons: [])
        raise InvalidTemplate, 'telegram_message requires Telegram' unless @kamigo_platform == :telegram
        message = { text: text.to_s }
        message[:reply_markup] = { inline_keyboard: buttons } unless buttons.empty?
        emit(message)
      end
    end

    class Renderer
      def initialize(view_paths:)
        @view_paths = view_paths
        @view_class = Class.new(ActionView::Base.with_empty_template_cache) { include Helpers }
      end

      def render(template:, platform:, assigns: {})
        platform = platform.to_sym
        configuration = Rendering.platform(platform)
        raise ArgumentError, 'unsupported rendering platform' unless configuration
        Mime::Type.register_alias('application/json', platform) unless Mime[platform]
        lookup = ActionView::LookupContext.new(@view_paths)
        format = lookup.exists?(template, [], false, [], formats: [platform]) ? platform : :text
        lookup.formats = [format]
        view = @view_class.new(lookup, assigns, nil)
        view.extend(configuration.helper) if configuration.helper
        messages = []
        view.instance_variable_set(:@kamigo_platform, platform)
        view.instance_variable_set(:@kamigo_messages, messages)
        rendered = view.render(template: template, formats: [format])
        if format == :text && messages.empty?
          message = configuration.fallback.call(rendered.to_s)
          raise InvalidTemplate, 'platform text fallback must return a Hash' unless message.is_a?(Hash)
          messages << message
        elsif !rendered.strip.empty?
          raise InvalidTemplate, 'platform templates must emit messages with <% ... %>, not render JSON or HTML'
        end
        messages
      end
    end


    register(:line, fallback: ->(text) { {type: 'text', text: text} })
    register(:telegram, fallback: ->(text) { {text: text} })
  end
end

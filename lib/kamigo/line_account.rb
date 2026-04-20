module Kamigo
  class LineAccount
    attr_accessor :name, :channel_id, :channel_secret, :channel_token
    attr_accessor :default_path, :default_http_method

    def initialize(name)
      @name = name.to_s
    end

    def client
      @client ||= Line::Bot::Client.new do |config|
        config.channel_id = channel_id
        config.channel_secret = channel_secret
        config.channel_token = channel_token
      end
    end

    def reset_client
      @client = nil
    end
  end
end

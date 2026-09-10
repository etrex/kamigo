require 'minitest/autorun'
require_relative '../../lib/kamigo/platforms/http_transport'
class HttpTransportTest < Minitest::Test
  class Response
    attr_reader :code
    def initialize(code: '200', chunks: ['{}'])
      @code, @chunks = code, chunks
    end
    def read_body
      @chunks.each { |chunk| yield chunk }
    end
    def [](key)
      key == 'x-line-request-id' ? 'request1' : nil
    end
  end
  class HTTP
    attr_accessor :use_ssl, :verify_mode, :open_timeout, :read_timeout, :write_timeout, :max_retries
    attr_reader :requests, :closed
    def initialize(response: Response.new, error: nil)
      @response, @error, @requests = response, error, []
    end
    def start
      yield self
    ensure
      @closed = true
    end
    def request(request)
      @requests << request
      raise @error if @error
      yield @response
    end
  end
  def transport(http, **options)
    Kamigo::Platforms::HttpTransport.new(token: -> { '123:SECRET' }, http_factory: ->(host, port) { @host, @port = host, port; http }, **options)
  end
  def test_line_fixed_endpoint_tls_and_no_retry
    http = HTTP.new
    receipt = transport(http).call(platform: :line, operation: :reply, payload: { replyToken: 'r', messages: [] })
    assert_equal ['api.line.me', 443], [@host, @port]
    assert_equal '/v2/bot/message/reply', http.requests.first.path
    assert_equal 'Bearer 123:SECRET', http.requests.first['Authorization']
    assert_equal OpenSSL::SSL::VERIFY_PEER, http.verify_mode
    assert http.use_ssl
    assert_equal 0, http.max_retries
    assert http.closed
    assert_equal 'request1', receipt[:request_id]
  end
  def test_telegram_endpoint_and_receipt
    http = HTTP.new(response: Response.new(chunks: ['{"ok":true,"result":{"message_id":42}}']))
    receipt = transport(http).call(platform: :telegram, operation: :send_message, payload: { chat_id: 'g', text: 'hello' })
    assert_equal 'api.telegram.org', @host
    assert_equal '/bot123:SECRET/sendMessage', http.requests.first.path
    assert_nil http.requests.first['Authorization']
    assert_equal 42, receipt[:message_id]
    refute_includes transport(http).inspect, 'SECRET'
  end
  def test_failure_classification_and_redaction
    rejected = HTTP.new(response: Response.new(code: '429'))
    error = assert_raises(Kamigo::Platforms::DeliveryRejected) { transport(rejected).call(platform: :line, operation: :push, payload: {}) }
    assert_equal 429, error.status
    [HTTP.new(response: Response.new(code: '503')), HTTP.new(error: IOError.new('https://api.telegram.org/bot123:SECRET/sendMessage'))].each do |http|
      error = assert_raises(Kamigo::Platforms::DeliveryUncertain) { transport(http).call(platform: :telegram, operation: :send_message, payload: {}) }
      refute_includes error.full_message, 'SECRET'
      assert_nil error.cause
      assert_equal 1, http.requests.size
      assert http.closed
    end
  end
  def test_request_and_response_limits
    http = HTTP.new
    assert_raises(ArgumentError) { transport(http, max_request_bytes: 1).call(platform: :line, operation: :push, payload: {}) }
    assert_empty http.requests
    http = HTTP.new(response: Response.new(chunks: ['{}', ' ' * 10]))
    assert_raises(Kamigo::Platforms::DeliveryUncertain) { transport(http, max_response_bytes: 4).call(platform: :line, operation: :push, payload: {}) }
    assert http.closed
  end
  def test_deadline_closes_connection_and_returns_uncertainty
    http = HTTP.new
    def http.request(request)
      @requests << request
      sleep 1
    end
    assert_raises(Kamigo::Platforms::DeliveryUncertain) do
      transport(http, deadline: 0.01).call(platform: :line, operation: :push, payload: {})
    end
    assert http.closed
    assert_equal 1, http.requests.size
  end

end

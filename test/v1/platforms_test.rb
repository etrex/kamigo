require 'minitest/autorun'
require_relative '../../lib/kamigo/event'
require_relative '../../lib/kamigo/platforms/line'
require_relative '../../lib/kamigo/platforms/telegram'
class PlatformsTest < Minitest::Test
  def test_line_authenticates_exact_raw_body_and_maps_group_actor
    adapter = Kamigo::Platforms::Line.new(secret: 'secret')
    body = JSON.generate(events: [{ webhookEventId: 'evt1', type: 'message', source: { userId: 'u', groupId: 'g' }, message: { type: 'text', text: 'hello' } }])
    signature = Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', 'secret', body))
    event = adapter.events(body: body, headers: { 'HTTP_X_LINE_SIGNATURE' => signature }, connection: 'bot1').first
    assert_equal 'u', event.actor_id
    assert_equal 'g', event.conversation_id
    assert_equal 'hello', event.text
    assert_raises(Kamigo::Platforms::VerificationError) { adapter.events(body: body + ' ', headers: { 'x-line-signature' => signature }, connection: 'bot1') }
  end

  def test_telegram_secret_and_delivery
    calls = []
    adapter = Kamigo::Platforms::Telegram.new(secret: 's', transport: ->(**args) { calls << args })
    body = JSON.generate(update_id: 1, message: { from: { id: 12 }, chat: { id: -30 }, text: 'hello' })
    assert_raises(Kamigo::Platforms::VerificationError) { adapter.events(body: body, headers: {}, connection: 'bot') }
    event = adapter.events(body: body, headers: { 'X-Telegram-Bot-Api-Secret-Token' => 's' }, connection: 'bot').first
    assert_equal '-30', event.conversation_id
    acknowledgements = []
    adapter.deliver(conversation_id: '-30', messages: [{ text: '<hello>' }]) { |item| acknowledgements << item }
    assert_equal({ text: '<hello>', chat_id: '-30' }, calls.first[:payload])
    assert_equal [[0]], acknowledgements.map { |item| item[:message_indexes] }
  end
  def test_delivery_rejects_oversize_before_any_transport_and_supports_line_reply
    calls = []
    telegram = Kamigo::Platforms::Telegram.new(secret: 's', transport: ->(**args) { calls << args })
    assert_raises(ArgumentError) { telegram.deliver(conversation_id: 'c', messages: [{ text: 'ok' }, { text: 'x' * 4097 }]) }
    assert_empty calls
    line = Kamigo::Platforms::Line.new(secret: 's', transport: ->(**args) { calls << args })
    acknowledgements = []
    line.deliver(reply_token: 'token', messages: [{ type: 'text', text: 'hello' }]) { |item| acknowledgements << item }
    assert_equal :reply, calls.first[:operation]
    assert_equal 'token', calls.first[:payload][:replyToken]
    assert_equal [[0]], acknowledgements.map { |item| item[:message_indexes] }
    assert_raises(ArgumentError) { line.deliver(conversation_id: 'c', messages: Array.new(6) { { type: 'text', text: 'x' } }) }
  end


  def test_telegram_acknowledges_each_confirmed_message_before_a_later_failure
    calls = 0
    adapter = Kamigo::Platforms::Telegram.new(secret: 's', transport: lambda do |**_arguments|
      calls += 1
      raise IOError, 'second send failed' if calls == 2
      { status: 200, message_id: 71 }
    end)
    acknowledgements = []

    assert_raises(IOError) do
      adapter.deliver(conversation_id: '-31', messages: [{ text: 'sent' }, { text: 'failed' }]) { |item| acknowledgements << item }
    end
    assert_equal [[0]], acknowledgements.map { |item| item[:message_indexes] }
    assert_equal 71, acknowledgements.first.dig(:provider_receipt, :message_id)
  end

end

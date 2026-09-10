require 'minitest/autorun'
require_relative '../../lib/kamigo/platforms/line'
require_relative '../../lib/kamigo/platforms/telegram'

class PlatformLeaveTest < Minitest::Test
  def test_line_leave_requires_an_empty_delivery_and_known_conversation_kind
    calls = []
    adapter = Kamigo::Platforms::Line.new(secret: 'synthetic-secret', transport: ->(**arguments) { calls << arguments; {status: 200} })
    result = adapter.deliver(conversation_id: 'group-123', messages: [], action: :leave_group)
    assert_equal({status: 200}, result)
    assert_equal({platform: :line, operation: :leave_group, payload: {conversation_id: 'group-123'}}, calls.first)
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: 'group-123', messages: [{type: 'text', text: 'bye'}], action: :leave_group) }
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: 'group-123', messages: [], reply_token: 'already-used', action: :leave_group) }
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: 'group-123', messages: [], action: :delete_group) }
  end

  def test_telegram_leave_requires_a_numeric_chat_id_and_empty_delivery
    calls = []
    adapter = Kamigo::Platforms::Telegram.new(secret: 'synthetic-secret', transport: ->(**arguments) { calls << arguments; {status: 200} })
    result = adapter.deliver(conversation_id: '-100123', messages: [], action: :leave_chat)
    assert_equal({status: 200}, result)
    assert_equal({platform: :telegram, operation: :leave_chat, payload: {chat_id: '-100123'}}, calls.first)
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: 'group-name', messages: [], action: :leave_chat) }
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: '-100123', messages: [{text: 'bye'}], action: :leave_chat) }
    assert_raises(ArgumentError) { adapter.deliver(conversation_id: '-100123', messages: [], action: :delete_chat) }
  end
end

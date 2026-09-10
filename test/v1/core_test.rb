require "minitest/autorun"
require "kamigo/event"
require "kamigo/router"
require "kamigo/dispatcher"
class CoreTest < Minitest::Test
  def event(text = "背包")
    Kamigo::Event.new(platform: :line, connection: "main", id: "1", actor_id: "u1", conversation_id: "g1", type: :message, text: text)
  end
  def test_rules_preserve_order_and_fallback
    router = Kamigo::Router.new do
      command "背包", to: "inventory#index"
      match(to: "later") { true }
      fallback to: "agent"
    end
    assert_equal "inventory#index", router.resolve(event)
    assert_equal "later", router.resolve(event("other"))
    assert_equal "agent", Kamigo::Router.new { fallback to: "agent" }.resolve(event)
  end
  def test_index_preserves_event_and_predicate_precedence
    first = Kamigo::Router.new do
      on :message, to: "event"
      command "背包", to: "command"
    end
    assert_equal "event", first.resolve(event)
    second = Kamigo::Router.new do
      match(to: "predicate") { true }
      command "背包", to: "command"
    end
    assert_equal "predicate", second.resolve(event)
    third = Kamigo::Router.new do
      command "背包", to: "first"
      command "背包", to: "second"
    end
    assert_equal "first", third.resolve(event)
  end
  def test_no_arbitrary_route_and_default_denial
    router = Kamigo::Router.new { command "背包", to: "inventory#index" }
    calls = 0
    dispatcher = Kamigo::Dispatcher.new(router: router, policy: ->(*) { false }, handlers: {"inventory#index" => -> { calls += 1 }})
    assert_raises(Kamigo::Unauthorized) { dispatcher.call(event) }
    assert_equal 0, calls
    assert_nil dispatcher.call(event("DELETE /users/1"))
  end
  def test_event_deep_copy_and_context_immutable
    input = {"nested" => [+"hello"]}
    ev = Kamigo::Event.new(platform: :line, connection: "main", id: "1", actor_id: nil, conversation_id: "g", type: :message, payload: input)
    input["nested"][0].replace("changed")
    assert_equal "hello", ev.payload["nested"][0]
    assert_raises(FrozenError) { ev.payload["nested"] << "x" }
  end
  def test_each_dispatch_owns_handler_instance
    klass = Class.new do
      def initialize; @calls = 0; end
      def call(event:, context:); @calls += 1; [event.actor_id, @calls]; end
    end
    d = Kamigo::Dispatcher.new(router: Kamigo::Router.new { command "背包", to: "index" }, handlers: {"index" => -> { klass.new }}, policy: ->(*) { true })
    results = 20.times.map { Thread.new { d.call(event) } }.map(&:value)
    assert_equal [["u1", 1]] * 20, results
  end
end

require 'minitest/autorun'
require 'tmpdir'
require 'kamigo'
class ControllerIntegrationTest < Minitest::Test
  class Greeting < Kamigo::Controller
    def hello
      render 'hello', name: event.actor_id
    end
  end
  def test_dispatches_per_event_to_platform_template_after_authorization
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, 'hello.line.erb'), '<% text @name %>')
      renderer = Kamigo::Rendering::Renderer.new(view_paths: [directory])
      router = Kamigo::Router.new { command 'hello', to: 'greeting#hello' }
      dispatcher = Kamigo::Dispatcher.new(router: router,
        handlers: {'greeting#hello' => Greeting.action(:hello, renderer: renderer)},
        policy: ->(context, _, _) { context.principal_id == 1 })
      events = 8.times.map do |n|
        Kamigo::Event.new(platform: 'line', connection: 'bot', id: n.to_s,
          actor_id: n.to_s, conversation_id: 'group', type: :message, text: 'hello')
      end
      results = events.map { |event| Thread.new { dispatcher.call(event, context: Kamigo::Context.new(principal_id: 1)) } }.map(&:value)
      assert_equal 8.times.map { |n| [{type: 'text', text: n.to_s}] }, results
      assert_raises(Kamigo::Unauthorized) { dispatcher.call(events.first) }
    end
  end
end

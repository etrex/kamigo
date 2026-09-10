require 'minitest/autorun'
require 'tmpdir'
require_relative '../../lib/kamigo/rendering/renderer'
class RenderingTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir
    @renderer = Kamigo::Rendering::Renderer.new(view_paths: [@directory])
  end
  def teardown
    FileUtils.remove_entry(@directory)
  end
  def test_platform_dsl_preserves_text_and_falls_back
    File.write(File.join(@directory, 'hello.line.erb'), '<% text @name %>')
    File.write(File.join(@directory, 'hello.text.erb'), 'Hello <%= @name %>')
    assert_equal [{ type: 'text', text: '<A & B>' }], @renderer.render(template: 'hello', platform: :line, assigns: { name: '<A & B>' })
    assert_equal [{ text: 'Hello <A & B>' }], @renderer.render(template: 'hello', platform: :telegram, assigns: { name: '<A & B>' })
  end
  def test_raw_platform_json_is_rejected
    File.write(File.join(@directory, 'bad.line.erb'), '{"text":"<%= @name %>"}')
    assert_raises(Kamigo::Rendering::InvalidTemplate) { @renderer.render(template: 'bad', platform: :line) }
  end
  def test_kamiflex_builder
    File.write(File.join(@directory, 'card.line.erb'), '<% line_flex do; bubble do; body do; text "Hello"; end; end; end %>')
    message = @renderer.render(template: 'card', platform: :line).first
    assert_equal 'flex', message[:type]
    assert_equal 'Hello', message.dig(:contents, :body, :contents, 0, :text)
  end
  def test_parallel_renders_do_not_share_message_buffers
    File.write(File.join(@directory, 'thread.line.erb'), '<% text @name %>')
    results = 12.times.map do |number|
      Thread.new { @renderer.render(template: 'thread', platform: :line, assigns: { name: number.to_s }) }
    end.map(&:value)
    assert_equal 12.times.map { |number| [{ type: 'text', text: number.to_s }] }, results
    refute Object.new.respond_to?(:bubble)
  end

  def test_an_adapter_can_register_a_platform_template_and_dsl
    slack_helpers = Module.new do
      def slack_blocks(text)
        emit(type: 'section', text: {type: 'mrkdwn', text: text})
      end
    end
    Kamigo::Rendering.register(:slack, helper: slack_helpers, fallback: ->(text) { {type: 'plain_text', text: text} })
    File.write(File.join(@directory, 'notice.slack.erb'), '<% slack_blocks @message %>')
    File.write(File.join(@directory, 'fallback.text.erb'), 'plain <%= @message %>')
    assert_equal [{type:'section',text:{type:'mrkdwn',text:'<hello>'}}], @renderer.render(template:'notice',platform: :slack,assigns:{message:'<hello>'})
    assert_equal [{type:'plain_text',text:'plain <hello>'}], @renderer.render(template:'fallback',platform: :slack,assigns:{message:'<hello>'})
  end

end

require 'benchmark'
require 'json'
require_relative '../lib/kamigo/event'
require_relative '../lib/kamigo/router'
count = Integer(ENV.fetch('ROUTES', '1000'))
iterations = Integer(ENV.fetch('ITERATIONS', '20000'))
router = Kamigo::Router.new do
  count.times { |i| command "command-#{i}", to: "handler-#{i}" }
  fallback to: 'fallback'
end
event = Kamigo::Event.new(platform: 'line', connection: 'main', id: '1', actor_id: 'u', conversation_id: 'g', type: :message, text: "command-#{count-1}")
context = Kamigo::Context.new
1000.times { router.resolve(event, context: context) }
GC.start
allocated = GC.stat(:total_allocated_objects)
seconds = Benchmark.realtime { iterations.times { router.resolve(event, context: context) } }
puts JSON.pretty_generate(ruby: RUBY_VERSION, routes: count, iterations: iterations, seconds: seconds, allocated_objects: GC.stat(:total_allocated_objects)-allocated, scope: 'in-process last exact route lookup only; no HTTP/DB/render')

# frozen_string_literal: true
require 'tmpdir'
require 'fileutils'
require 'etc'
require 'socket'
require 'json'
require 'active_record'
require 'thread'
require_relative '../../lib/kamigo/event'
require_relative '../../lib/kamigo/reliability'
require_relative '../../db/migrate/20260909000002_create_kamigo_delivery'

directory = Dir.mktmpdir('kamigo-reliability-', '/tmp')
probe = TCPServer.new('127.0.0.1',0)
port = probe.addr[1]
probe.close
binary = ENV.fetch('PG_BIN','/opt/homebrew/opt/postgresql@15/bin')
pg_environment = ENV.keys.grep(/^PG/).to_h { |key| [key,nil] }
run_pg = lambda do |command,*arguments|
  abort "PostgreSQL #{command} failed" unless system(pg_environment,File.join(binary,command),*arguments,out:File::NULL,err:File::NULL)
end
started = false
begin
  run_pg.call('initdb','-D',File.join(directory,'data'),'-A','trust','--encoding=UTF8','--no-locale')
  run_pg.call('pg_ctl','-D',File.join(directory,'data'),'-l',File.join(directory,'postgres.log'),'-o',"-k #{directory} -p #{port} -c listen_addresses=''",'-w','start')
  started = true
  ActiveRecord::Base.establish_connection(adapter:'postgresql',host:directory,port:port,database:'postgres',username:Etc.getpwuid.name,pool:10,checkout_timeout:5)
  ActiveRecord::Migration.verbose=false
  CreateKamigoDelivery.new.change
  ActiveRecord::Base.connection.create_table(:acceptance_business_records){|table|table.string :value,null:false}
  business_record=Class.new(ActiveRecord::Base){self.table_name='acceptance_business_records'}
  event=Kamigo::Event.new(platform:'line',connection:'main',id:'same-event',actor_id:'user',conversation_id:'group',type: :message)
  dispatcher=Object.new
  dispatcher.define_singleton_method(:call) do |_event,context:|
    business_record.create!(value:context.principal_id.to_s)
    [{type:'text',text:'hello'}]
  end
  receiver=Kamigo::Reliability::Receiver.new(adapter:nil,dispatcher:dispatcher,context_resolver:->(_event){Kamigo::Context.new(principal_id:1)})
  start=Queue.new
  results=Queue.new
  threads=2.times.map do
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        start.pop
        results << receiver.process(event)
      rescue StandardError => error
        results << error
      end
    end
  end
  2.times{start << true};threads.each(&:join)
  receipt_results=2.times.map{results.pop}
  abort receipt_results.inspect unless receipt_results.sort_by(&:to_s)==[:duplicate,:processed]
  abort 'duplicate business effect' unless business_record.count==1 && Kamigo::Reliability::Receipt.count==1 && Kamigo::Reliability::Outbox.count==1

  outbox=Kamigo::Reliability::Outbox.first
  attempts=0
  lock=Mutex.new
  adapter=Object.new
  adapter.define_singleton_method(:deliver){|**|lock.synchronize{attempts+=1};sleep 0.2;{status:200}}
  delivery=Kamigo::Reliability::Delivery.new(adapter_resolver:->(*){adapter})
  delivery_start=Queue.new
  delivery_results=Queue.new
  workers=2.times.map do
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        delivery_start.pop
        delivery_results << delivery.call(outbox.id)
      rescue StandardError => error
        delivery_results << error
      end
    end
  end
  2.times{delivery_start << true};workers.each(&:join)
  outcomes=2.times.map{delivery_results.pop}
  abort outcomes.inspect unless outcomes.sort_by(&:to_s)==[:not_pending,:sent] && attempts==1 && outbox.reload.state=='sent'

  first_ordered=Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'ordered-chat',messages:[{text:'first'}],delivery_options:{},state:'pending')
  second_ordered=Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'ordered-chat',messages:[{text:'second'}],delivery_options:{},state:'pending')
  first_started=Queue.new
  release_first=Queue.new
  ordered_messages=[]
  ordered_adapter=Object.new
  ordered_adapter.define_singleton_method(:deliver) do |messages:,**|
    text=messages.fetch(0).fetch(:text)
    if text=='first'
      first_started << true
      release_first.pop
    end
    ordered_messages << text
    {status:200}
  end
  ordered_delivery=Kamigo::Reliability::Delivery.new(adapter_resolver:->(*){ordered_adapter})
  first_result=Queue.new
  first_thread=Thread.new do
    ActiveRecord::Base.connection_pool.with_connection { first_result << ordered_delivery.call(first_ordered.id) }
  rescue StandardError => error
    first_result << error
  end
  first_started.pop
  later_while_first_sends=ordered_delivery.call(second_ordered.id)
  release_first << true
  first_thread.join
  earlier_result=first_result.pop
  later_retry=ordered_delivery.call(second_ordered.id)
  ordered_results=[earlier_result,later_while_first_sends,later_retry]
  abort({results:ordered_results,messages:ordered_messages}.inspect) unless ordered_results==[:sent,:blocked,:sent] && ordered_messages==%w[first second]

  race_created=Queue.new
  release_race=Queue.new
  race_first_id=Queue.new
  race_second_id=Queue.new
  race_errors=Queue.new
  race_first_thread=Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      Kamigo::Reliability::Outbox.transaction do
        row=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'commit-race',messages:[{text:'race first'}])
        race_first_id << row.id
        race_created << true
        release_race.pop
      end
    end
  rescue StandardError => error
    race_errors << error
  end
  race_created.pop
  race_second_thread=Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      row=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'commit-race',messages:[{text:'race second'}])
      race_second_id << row.id
    end
  rescue StandardError => error
    race_errors << error
  end
  sleep 0.2
  second_committed_early=begin race_second_id.pop(true); rescue ThreadError; nil end
  ready_during_uncommitted=Kamigo::Reliability::Delivery.ready_ids(limit:10)
  abort({second_committed_early:second_committed_early,ready:ready_during_uncommitted}.inspect) if second_committed_early || ready_during_uncommitted.any?
  release_race << true
  race_first_thread.join
  race_second_thread.join
  raise race_errors.pop unless race_errors.empty?
  committed_first_id=race_first_id.pop
  committed_second_id=race_second_id.pop
  race_ready_first=Kamigo::Reliability::Delivery.ready_ids(limit:10)
  abort race_ready_first.inspect unless race_ready_first==[committed_first_id] && committed_first_id < committed_second_id
  race_messages=[]
  race_adapter=Object.new
  race_adapter.define_singleton_method(:deliver){|messages:,**|race_messages << messages.fetch(0).fetch(:text);{status:200}}
  race_delivery=Kamigo::Reliability::Delivery.new(adapter_resolver:->(*){race_adapter})
  race_delivery.call(committed_first_id)
  abort Kamigo::Reliability::Delivery.ready_ids(limit:10).inspect unless Kamigo::Reliability::Delivery.ready_ids(limit:10)==[committed_second_id]
  race_delivery.call(committed_second_id)
  abort race_messages.inspect unless race_messages==['race first','race second']

  Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'blocked-chat',messages:[{text:'in flight'}],delivery_options:{},state:'sending')
  100.times do |number|
    Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'blocked-chat',messages:[{text:"blocked #{number}"}],delivery_options:{},state:'pending')
  end
  independent=Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'independent-chat',messages:[{text:'independent'}],delivery_options:{},state:'pending')
  ready_ids=Kamigo::Reliability::Delivery.ready_ids(limit:100)
  fair_ready=ready_ids==[independent.id]
  abort({ready_ids:ready_ids,independent:independent.id}.inspect) unless fair_ready

  puts JSON.generate(receipts:Kamigo::Reliability::Receipt.count,business_effects:business_record.count,
    outboxes:Kamigo::Reliability::Outbox.count,delivery_attempts:attempts,state:outbox.state,
    ordered_results:ordered_results,ordered_messages:ordered_messages,
    uncommitted_blocked:second_committed_early.nil? && ready_during_uncommitted.empty?,race_messages:race_messages,fair_ready:fair_ready)
ensure
  ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
  run_pg.call('pg_ctl','-D',File.join(directory,'data'),'-m','fast','-w','stop') if started
  FileUtils.remove_entry(directory) if File.exist?(directory)
end

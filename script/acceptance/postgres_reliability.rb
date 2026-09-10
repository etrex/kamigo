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
require_relative '../../db/migrate/20260910000001_add_kamigo_outbox_stream_heads'

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
  upgrade_pending=Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'upgrade-chat',messages:[{text:'old pending'}],delivery_options:{},state:'pending')
  upgrade_sending_ids=2.times.map do |number|
    Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'upgrade-chat',messages:[{text:"old sending #{number}"}],delivery_options:{},state:'sending').id
  end
  AddKamigoOutboxStreamHeads.new.up
  Kamigo::Reliability::Outbox.reset_column_information
  upgrade_quarantine=upgrade_pending.reload.stream_head? && Kamigo::Reliability::Outbox.where(id:upgrade_sending_ids).pluck(:state).uniq==['uncertain']
  abort 'stream head upgrade did not quarantine later sending rows' unless upgrade_quarantine
  Kamigo::Reliability::Outbox.where(conversation_id:'upgrade-chat').delete_all
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

  first_ordered=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'ordered-chat',messages:[{text:'first'}])
  second_ordered=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'ordered-chat',messages:[{text:'second'}])
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
  holder_pid=Queue.new
  waiter_pid=Queue.new
  race_errors=Queue.new
  race_first_thread=Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      holder_pid << ActiveRecord::Base.connection.select_value('SELECT pg_backend_pid()')
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
      waiter_pid << ActiveRecord::Base.connection.select_value('SELECT pg_backend_pid()')
      row=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'commit-race',messages:[{text:'race second'}])
      race_second_id << row.id
    end
  rescue StandardError => error
    race_errors << error
  end
  observed_holder_pid=holder_pid.pop
  observed_waiter_pid=waiter_pid.pop
  lock_deadline=Process.clock_gettime(Process::CLOCK_MONOTONIC)+5
  advisory_wait_observed=false
  until advisory_wait_observed
    advisory_wait_observed=ActiveRecord::Base.connection.select_value(<<~SQL)
      SELECT EXISTS (
        SELECT 1
        FROM pg_locks waiting
        JOIN pg_locks holding
          ON holding.locktype = waiting.locktype
         AND holding.database IS NOT DISTINCT FROM waiting.database
         AND holding.classid IS NOT DISTINCT FROM waiting.classid
         AND holding.objid IS NOT DISTINCT FROM waiting.objid
         AND holding.objsubid IS NOT DISTINCT FROM waiting.objsubid
        WHERE waiting.locktype = 'advisory'
          AND waiting.pid = #{Integer(observed_waiter_pid)}
          AND waiting.granted = FALSE
          AND holding.pid = #{Integer(observed_holder_pid)}
          AND holding.granted = TRUE
          AND holding.pid = ANY(pg_blocking_pids(waiting.pid))
      )
    SQL
    abort 'second enqueue never waited on the first stream advisory lock' if Process.clock_gettime(Process::CLOCK_MONOTONIC)>lock_deadline
    sleep 0.01 unless advisory_wait_observed
  end
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

  maintenance_messages=[]
  maintenance_adapter=Object.new
  maintenance_adapter.define_singleton_method(:deliver){|messages:,**|maintenance_messages << messages.fetch(0).fetch(:text);{status:200}}
  maintenance_delivery=Kamigo::Reliability::Delivery.new(adapter_resolver:->(*){maintenance_adapter})
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO kamigo_outbox(platform,connection,conversation_id,messages,delivery_options,state,stream_head,created_at,updated_at)
    SELECT 'telegram','main','expiry-chat','[{"text":"expiry old"}]'::json,'{}'::json,'pending',(number=1),CURRENT_TIMESTAMP-INTERVAL '8 days',CURRENT_TIMESTAMP
    FROM generate_series(1,2501) AS number
  SQL
  expiry_next=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'expiry-chat',messages:[{text:'expiry next'}])
  expiry_batches=3.times.map { Kamigo::Reliability::Outbox.expire_stale_pending!(before:Time.now.utc-7*86_400,limit:1000) }
  abort 'bounded pending expiry did not promote the fresh successor' unless expiry_batches==[1000,1000,501] && expiry_next.reload.stream_head?
  maintenance_delivery.call(expiry_next.id)
  expiry_next.update_columns(created_at:Time.now.utc-8*86_400)
  terminal_deleted=Kamigo::Reliability::Outbox.delete_stale_terminal!(before:Time.now.utc-7*86_400,limit:10)
  abort 'terminal retention failed' unless terminal_deleted==1 && !Kamigo::Reliability::Outbox.exists?(expiry_next.id)

  recovery_first=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'recovery-chat',messages:[{text:'recovery old'}])
  recovery_second=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'recovery-chat',messages:[{text:'recovery next'}])
  recovery_first.update_columns(state:'sending',updated_at:Time.now.utc-600)
  recovered_count=Kamigo::Reliability::Outbox.recover_stale_sending!(before:Time.now.utc-120,limit:10)
  abort 'sending recovery did not quarantine and promote' unless recovered_count==1 && recovery_first.reload.state=='uncertain' && recovery_second.reload.stream_head?
  maintenance_delivery.call(recovery_second.id)
  abort maintenance_messages.inspect unless maintenance_messages==['expiry next','recovery next']

  Kamigo::Reliability::Outbox.create!(platform:'telegram',connection:'main',conversation_id:'blocked-chat',messages:[{text:'in flight'}],delivery_options:{},state:'sending',stream_head:true)
  ActiveRecord::Base.connection.execute(<<~SQL)
    INSERT INTO kamigo_outbox(platform,connection,conversation_id,messages,delivery_options,state,stream_head,created_at,updated_at)
    SELECT 'telegram','main','blocked-chat','[{"text":"blocked"}]'::json,'{}'::json,'pending',FALSE,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP
    FROM generate_series(1,1000000)
  SQL
  independent=Kamigo::Reliability::Outbox.enqueue!(platform:'telegram',connection:'main',conversation_id:'independent-chat',messages:[{text:'independent'}])
  ready_ids=Kamigo::Reliability::Delivery.ready_ids(limit:100)
  fair_ready=ready_ids==[independent.id]
  abort({ready_ids:ready_ids,independent:independent.id}.inspect) unless fair_ready
  explain=ActiveRecord::Base.connection.execute(<<~SQL).first.fetch('QUERY PLAN').then { |value| JSON.parse(value) }
    EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
    SELECT id FROM kamigo_outbox
    WHERE stream_head = TRUE AND state = 'pending'
    ORDER BY id LIMIT 100
  SQL
  index_names=[]
  walk_plan=lambda do |node|
    index_names << node['Index Name'] if node['Index Name']
    Array(node['Plans']).each { |child| walk_plan.call(child) }
  end
  walk_plan.call(explain.first.fetch('Plan'))
  ready_execution_ms=explain.first.fetch('Execution Time')
  ready_index_used=index_names.include?('kamigo_outbox_ready_heads')
  abort({indexes:index_names,execution_ms:ready_execution_ms}.inspect) unless ready_index_used && ready_execution_ms < 250

  puts JSON.generate(receipts:Kamigo::Reliability::Receipt.count,business_effects:business_record.count,
    outboxes:Kamigo::Reliability::Outbox.count,delivery_attempts:attempts,state:outbox.state,
    ordered_results:ordered_results,ordered_messages:ordered_messages,
    advisory_wait_observed:advisory_wait_observed,
    uncommitted_blocked:second_committed_early.nil? && ready_during_uncommitted.empty?,race_messages:race_messages,
    upgrade_quarantine:upgrade_quarantine,maintenance:true,expiry_batches:expiry_batches,
    fair_ready:fair_ready,fair_backlog:1000000,ready_index_used:ready_index_used,ready_execution_ms:ready_execution_ms)
ensure
  release_race << true rescue nil
  [race_first_thread,race_second_thread].compact.each { |thread| thread.join(0.2) rescue nil }
  ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
  run_pg.call('pg_ctl','-D',File.join(directory,'data'),'-m','fast','-w','stop') if started
  FileUtils.remove_entry(directory) if File.exist?(directory)
end

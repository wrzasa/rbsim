require 'rbsim'

model = RBSim.model do

  program :wget do |opts|
    sent = 0
    on_event :send do
      cpu do |cpu|
        150/cpu.performance
      end
      send_data to: opts[:target], size: 1024, type: :request, content: sent
      log "Sent data in process #{process.name} #{sent}"
      sent += 1
      delay_for 50
      register_event :send if sent < opts[:count]
    end

    on_event :data_received do |data|
      log "Got data #{data} in process #{process.name}"
      stats :request_served, process.name
    end

    register_event :send
  end

  program :apache_static do
    on_event :data_received do |data|
      log "Got #{data.type} from: #{data.src}, size: #{data.size}, content: #{data.content}"
      cpu do |cpu|
        100*data.size / cpu.performance
      end
      send_data to: data.src, size: data.size * 10, type: :response, content: data.content
      log "Responded to: #{data.src} with content: #{data.content}"
    end
  end

  program :apache_php do |name|
    on_event :data_received do |data|
      stats_start :working, name
      log "#{name} start #{data.type} #{data.src} #{data.content}"
      if data.type == :request
        cpu do |cpu|
          100*data.size / cpu.performance
        end
        send_data to: :db, size: data.size/10, type: :sql, content: { client: data.src, content: data.content }
      else
        cpu do |cpu|
          500*data.size / cpu.performance
        end
        send_data to: data.content[:client], size: data.size*2, type: :sql, content: data.content[:content]
      end
      log "#{name} finished #{data.type} #{data.src} #{data.content}"
      stats_stop :working, name
    end
  end

  program :mysql do
    on_event :data_received do |data|
      stats_start :query, :mysql
      log "DB start #{data.src} #{data.content}"
      delay_for (data.size * rand).to_i
      send_data to: data.src, size: data.size*1000, type: :db_response, content: data.content
      log "DB finish #{data.src} #{data.content}"
      stats_stop :query, :mysql
    end
  end

  node :desktop do
    cpu 100
  end

  node :laptop do
    cpu 100
  end

  node :gandalf do
    cpu 140000
    cpu 140000
  end

  node :dbserver do
    cpu 500
  end

  new_process :client1, program: :wget, args: { target: :server1, count: 3 }
  new_process :client2, program: :wget, args: { target: :server2, count: 3 }

  new_process :server1, program: :apache_php, args: 'apache1'
  new_process :server2, program: :apache_php, args: 'apache2'
  new_process :db, program: :mysql

  net :net01, bw: 1024
  net :net02, bw: 512
  net :lan, bw: 10240

  route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true
  route from: :laptop, to: :gandalf, via: [ :net01, :net02 ], twoway: true
  route from: :gandalf, to: :dbserver, via: [ :lan ], twoway: true

  put :server1, on: :gandalf
  put :server2, on: :gandalf
  put :db, on: :dbserver

  put :client1, on: :desktop
  put :client2, on: :laptop

end

# TODO: modify CPU load event handling, to enable random CPU load time!
# TODO: potrzebne gotowe narzędzie generujące raport obciążenia poszczególnych zasobów

# TODO: use this proof-of-concept to embedd logger into RBSim!
=begin
model.simulator.cb_for :transition, :after do |t, e|
#  puts ">> #{e.clock} #{e.transition}"##{e.binding.map {|k, v| "#{k}: #{v}" }}" #if e.clock > 90000
  if e.transition == 'event::log'
    message = e.binding[:process][:val].serve_system_event(:log)[:args]
    puts "#{e.clock} #{message}"
  end
end
=end

#model.simulator.cb_for :clock, :after do |t, e|
#  puts e.clock
#end

=begin
model.logger do |clock, message|
  puts "MY LOGGER: #{clock} #{message}"
end
=end

model.run

p model.stats_summary
p model.stats_data

model.stats_print


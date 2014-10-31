require 'rbsim'

model = RBSim.model do

  program :wget do |target|
    10.times do |i|
      send_data to: target, size: 1024, type: :request, content: i
      log "Sent data in process #{process.name} #{i}"
      delay_for 100
    end

    with_event :data_received do |data|
      log "Got data #{data} in process #{process.name}"
    end
  end

  program :apache do
    with_event :data_received do |data|
      log "Got #{data.type} from: #{data.src}, size: #{data.size}, content: #{data.content}"
      cpu do |cpu|
        data.size / cpu.performance
      end
      delay_for 750
      send_data to: data.src, size: data.size * 10, type: :response, content: data.content
      log "Responded to #{data.content}"
    end
  end

  node :desktop do
    cpu 100
  end

  node :gandalf do
    cpu 200
    cpu 200
  end

  new_process :client, program: :wget, args: :server
  new_process :server, program: :apache, args: :client

  net :net01, bw: 1024
  net :net02, bw: 512

  route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true

  put :client, on: :desktop
  put :server, on: :gandalf

end

# TODO: use this proof-of-concept to embedd logger into RBSim!
model.simulator.cb_for :transition, :after do |t, e|
  if e.transition == 'event::log'
    message = e.binding[:process][:val].serve_system_event(:log)[:args]
    puts "#{e.clock} #{message}"
  end
end

#model.simulator.cb_for :clock, :after do |t, e|
#  puts e.clock
#end


model.run

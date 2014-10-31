require 'rbsim'

model = RBSim.model do

  program :wget do |target|
    10.times do
      send_data to: target, size: 1024, type: :request
      delay_for 1000
    end

    with_event :data_received do |data|
      # FIXME: chciałbym to mieć dostęp do parametrów progamu/procesu,
      # np. process.name
      # A może mam?
      puts "Got data #{data}"
    end
  end

  program :apache do
    with_event :data_received do |data|
      cpu do |cpu|
        data.size / cpu.performance
      end
      delay_for 750
      send_data to: data.src, size: data.size * 10, type: :response
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

model.simulator.cb_for :transition, :after do |t, e|
  puts e.transition
end

p model.tcpn.places.map { |place| place.name }
p model.tcpn.transitions.map { |t| t.name }

model.run
model.tcpn.marking.each do |place, marking|
  puts "="*80
  puts place
  puts marking
end

require 'hlmodel'
require 'tcpn'

class RBSim::HLModel::Process
  include TCPN::TokenValue
  token_value_only :id
end

model = TCPN.read 'lib/tcpn/model/application.rb'

process = RBSim::HLModel::Process.new(:node01)
10.times { process.register_event(:delay_for, time: 10) }
process.register_event(:delay_for, time: 100)

model.set_marking_for 'process', process

sim = TCPN.sim model

sim.cb_for :transition, :after do |t, e|
  puts "#{e.transition} #{e.binding.map { |k, v| "#{k}: #{v.timestamp}"}.join ',' }"
  #puts model.marking
end

sim.cb_for :clock, :after do |t, e|
  puts e.clock #if (tick += 1) % 100 == 0
end

sim.run

puts model.marking

process = sim.model.marking_for 'process'
p process

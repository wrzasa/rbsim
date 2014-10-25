require 'hlmodel'
require 'tcpn'

class RBSim::HLModel::Process
  include TCPN::TokenValue
  token_value_only :id
end

model = TCPN.read 'lib/tcpn/model/application.rb'

process = RBSim::HLModel::Process.new(:node01)
process.register_event(:delay_for, time: 10)
process.register_event(:delay_for, time: 100)

model.set_marking_for 'process', process

sim = TCPN.sim model

sim.cb_for :transition, :after do |t, e|
  p t
  p e
  puts "-"*30
end

sim.run

process = sim.model.marking_for 'process'
p process

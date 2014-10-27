require 'hlmodel'
require 'tcpn'

class ProcessToken < RBSim::HLModel::Process
  include TCPN::TokenMethods
end

class CPU
  attr_accessor :node, :performance
  def initialize(node, performance)
    @node, @performance = node, performance
  end
end

class CPUToken < CPU
  include TCPN::TokenMethods
end

class Handler
  def call(*)
    2345
  end
end

def doproc(&block)
  return block
end

model = TCPN.read 'lib/tcpn/model/application.rb'

process = ProcessToken.new(:node01)
process.with_event :data do
  puts "*"*80
  puts "* GOT data EVENT"
  puts "*"*80
end
#handler = Handler.new
handler = Proc.new { |cpu| 1000/cpu.performance } # java error if handler is set to Proc or lambda...
#handler = Proc.new { |cpu| 1000 } # java error if handler is set to Proc or lambda...
#handler = doproc do |cpu|
#  1000/cpu.performance
#end
process.register_event(:cpu, block: handler )
process.register_event(:cpu, block: handler )
process.register_event(:data, data_id: 123321 )
#process.register_event(:delay_for, time: 100)
model.add_marking_for 'process', process

cpu = CPUToken.new(:node01, 10)
model.add_marking_for 'CPU', cpu

sim = TCPN.sim model

sim.cb_for :transition, :after do |t, e|
  puts "==> FIRING: #{e.transition} #{e.binding.map { |k, v| "#{k}: #{v}"}.join ',' }"
  #puts model.marking
end

sim.cb_for :clock, :after do |t, e|
  puts e.clock #if (tick += 1) % 100 == 0
end

sim.run

puts model.marking

process = sim.model.marking_for 'process'
p process

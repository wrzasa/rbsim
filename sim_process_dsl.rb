require 'rbsim'
require 'tcpn'

# DONE: Use this example to create integration spec for DSL, HLModel and TCPN model
# of application process
#
# TODO: test if new_process inside a process works well with and without TCPN
# (see: spec/dsl_and_hlmodel/new_process_spec.rb -- there is no such test there!

class CPU
  attr_accessor :node, :performance
  def initialize(node, performance)
    @node, @performance = node, performance
  end
end

class CPUToken < CPU
  include TCPN::TokenMethods
end

hlmodel = RBSim.dsl do
  new_process :worker do
    with_event :data do |volume|
      delay_for 100
      cpu do |c|
        12/c.performance
      end
    end
    delay_for 100
    cpu do |cpu|
      100/cpu.performance
    end
    register_event :data, 1000
  end
end


process_token = hlmodel.processes[:worker]
process_token.node = :node01
cpu_token = CPUToken.new(:node01, 10)


tcpn = TCPN.read 'lib/tcpn/model/application.rb'

tcpn.add_marking_for 'CPU', cpu_token
tcpn.add_marking_for 'process', process_token

sim = TCPN.sim tcpn

transitions = []
sim.cb_for :transition, :after do |t, e|
  transitions << e.transition
  puts "==> FIRING: #{e.transition} #{e.binding.map { |k, v| "#{k}: #{v}"}.join ',' }"
  #puts model.marking
end

sim.run

p transitions

puts " MARKING ".center(70, '=')
tcpn.marking.each do |p, m|
  puts "#{p}: #{m}"
end

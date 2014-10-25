require 'hlmodel'
require 'tcpn'

module TokenMethods
  def self.included(base)
    base.class_eval do
      include TCPN::TokenValue
    end
    base.token_value_only :__token_id__
  end
  attr_reader :__token_id__

  def initialize(*)
    super
    @__token_id__ = object_id
  end

  def token_id
    @__token_id__
  end
end

class ProcessToken < RBSim::HLModel::Process
  include TokenMethods
end

model = TCPN.read 'lib/tcpn/model/application.rb'

processes = (1..2).map do
  process = ProcessToken.new(:node01)
  10.times { process.register_event(:delay_for, time: 10) }
  process.register_event(:delay_for, time: 100)
  model.add_marking_for 'process', process
end


sim = TCPN.sim model

sim.cb_for :transition, :after do |t, e|
  puts "#{e.transition} #{e.binding.map { |k, v| "#{k}: #{v}"}.join ',' }"
  #puts model.marking
end

sim.cb_for :clock, :after do |t, e|
  puts e.clock #if (tick += 1) % 100 == 0
end

sim.run

puts model.marking

process = sim.model.marking_for 'process'
p process

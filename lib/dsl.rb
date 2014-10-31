require 'docile'
require 'tokens'
require 'dsl/infrastructure'
require 'dsl/program'
require 'dsl/process'
require 'dsl/mapping'

module RBSim

  def self.dsl(&block)
    hlmodel = RBSim::HLModel::Model.new
    Docile.dsl_eval(RBSim::DSL.new(hlmodel), &block)
    hlmodel
  end

  # TODO: after implementing marking TCPN from the HLModel, update spec/integration/new_process_spec.rb!

  def self.model(&block)
    Simulator.new &block
  end
end

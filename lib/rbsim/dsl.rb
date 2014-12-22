require 'docile'
require 'rbsim/tokens'
require 'rbsim/dsl/infrastructure'
require 'rbsim/dsl/program'
require 'rbsim/dsl/process'
require 'rbsim/dsl/mapping'

module RBSim

  def self.dsl(&block)
    hlmodel = RBSim::HLModel::Model.new
    Docile.dsl_eval(RBSim::DSL.new(hlmodel), &block)
    hlmodel
  end

  # TODO: after implementing marking TCPN from the HLModel, update spec/integration/new_process_spec.rb!

  def self.model(params = {}, &block)
    Simulator.new params, &block
  end
end

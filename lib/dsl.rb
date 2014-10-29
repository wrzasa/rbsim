require 'docile'
require 'tcpn/tokens'
require 'dsl/infrastructure.rb'
require 'dsl/program.rb'
require 'dsl/process.rb'
require 'dsl/mapping.rb'

module RBSim

  def self.dsl(&block)
    @model = RBSim::HLModel::Model.new
    Docile.dsl_eval(RBSim::DSL.new(@model), &block)
    @model
  end

  # TODO: after implementing marking TCPN from the HLModel, update spec/integration/new_process_spec.rb!

end

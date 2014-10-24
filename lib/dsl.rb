require 'docile'
require 'dsl/infrastructure.rb'

module RBSim

  def self.dsl(&block)
    @model = RBSim::HLModel::Model.new
    Docile.dsl_eval(RBSim::DSL.new(@model), &block)
    @model
  end

end

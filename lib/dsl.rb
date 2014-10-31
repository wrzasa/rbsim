require 'docile'
require 'tokens'
require 'dsl/infrastructure.rb'
require 'dsl/program.rb'
require 'dsl/process.rb'
require 'dsl/mapping.rb'

module RBSim

  def self.dsl(&block)
    hlmodel = RBSim::HLModel::Model.new
    Docile.dsl_eval(RBSim::DSL.new(hlmodel), &block)
    hlmodel
  end

  # TODO: after implementing marking TCPN from the HLModel, update spec/integration/new_process_spec.rb!

  def self.model(&block)
    puts "="*80
    hlmodel = dsl &block
    tcpn = TCPN.read 'lib/tcpn/model.rb'
    # :nets, :routes, :processes, :mapping
    hlmodel.nets.each do |net|
      tcpn.add_marking_for 'net', net
    end

    hlmodel.processes.each do |process|
      tcpn.add_marking_for 'process', process
    end

    tcpn.add_marking_for 'routes', hlmodel.routes
    tcpn.add_marking_for 'mapping', hlmodel.mapping

    tcpn
  end

end

module RBSim

  class Simulator
    def initialize(&block)
      @block = block
    end

    def run
      simulator.run
    end

    def hlmodel
      if @hlmodel.nil?
        @hlmodel = RBSim::HLModel::Model.new
        Docile.dsl_eval(RBSim::DSL.new(@hlmodel), &@block)
      end
      @hlmodel
    end

    def tcpn
      if @tcpn.nil?
        @tcpn = TCPN.read 'tcpn/model.rb'
        hlmodel.nets.each do |net|
          @tcpn.add_marking_for 'net', net
        end

        hlmodel.nodes.each do |node|
          node.cpus.each do |cpu|
            cpu.node = node.name
            @tcpn.add_marking_for 'CPU', cpu
          end
        end

        hlmodel.processes.each do |name, process|
          process.node = hlmodel.mapping[name]
          @tcpn.add_marking_for 'process', process
        end


        @tcpn.add_marking_for 'routes', hlmodel.routes
        @tcpn.add_marking_for 'mapping', hlmodel.mapping
      end

      @tcpn
    end

    def simulator
      @simulator ||= TCPN.sim(tcpn)
    end

  end

end

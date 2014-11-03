module RBSim

  class Simulator
    def initialize(&block)
      @block = block
      @logger = default_logger
      @stats_collector = default_stats_collector
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

        @tcpn.add_marking_for 'data to receive', Tokens::DataQueueToken.new

      end

      @tcpn
    end

    def simulator
      if @simulator.nil?
        @simulator = TCPN.sim(tcpn)

        set_logger_callbacks
        set_stats_collector_callbacks

      end
      @simulator
    end

    def logger(&block)
      @logger = block
    end

    private

    def default_logger
      proc do |clock, message|
        puts "#{clock}: #{message}"
      end
    end

    def default_stats_collector
      Statistics.new
    end

    def set_logger_callbacks
      @simulator.cb_for :transition, :after do |t, e|
        if e.transition == 'event::log'
          message = e.binding[:process][:val].serve_system_event(:log)[:args]
          @logger.call e.clock, message
        end
      end
    end

    def set_stats_collector_callbacks
      @simulator.cb_for :transition, :after do |t, e|
        [ :stats, :stats_start, :stats_stop ].each do |event|
          if e.transition == "event::#{event}"
            tag = e.binding[:process][:val].serve_system_event(event)[:args]
            @stats_collector.send :event, event, tag, e.clock
          end
        end
      end
    end

  end

end

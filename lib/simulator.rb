module RBSim

  class Simulator
    attr_reader :clock

    def initialize(&block)
      @block = block
      @logger = default_logger
      @stats_collector = Statistics.new
      @resource_stats_collector = Statistics.new
      @clock = 0
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
        set_clock_callbacks

      end
      @simulator
    end

    def logger(&block)
      @logger = block
    end

    def stats_summary
      { application: @stats_collector.hash, resources: @resource_stats_collector.hash }
    end

    def stats_data
      { application: @stats_collector, resources: @resource_stats_collector }
    end

    def stats_print
      puts
      puts "="*80
      puts "STATISTICS:\n\n"
      puts "Time: %.6fs" % @clock.to_f.in_seconds

      puts
      puts "APPLICATION"
      puts "-"*80
      @stats_collector.print

      puts
      puts "RESOURCES"
      puts "-"*80
      @resource_stats_collector.print
      puts "="*80

    end

    private

    def default_logger
      proc do |clock, message|
        puts "%.3f: #{message}" % (clock.to_f.in_seconds)
      end
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
        if e.transition == "event::stats"
          process = e.binding[:process][:val]
          event = [ :stats, :stats_start, :stats_stop ].select { |e| process.has_event? e }.first
          params = process.serve_system_event(event)[:args]
          @stats_collector.event event.to_s.sub(/^stats_/,'').to_sym, params, e.clock
        elsif e.transition == "event::cpu"
          node = e.binding[:cpu][:val].node
          @resource_stats_collector.event :start, { group_name: 'CPU', tag: node }, e.clock
        elsif e.transition == "event::cpu_finished"
          node = e.binding[:cpu_and_process][:val][:cpu].node
          @resource_stats_collector.event :stop, { group_name: 'CPU', tag: node }, e.clock
        end
      end

      @simulator.cb_for :place, :remove do |t, e|
        if e.place == 'net'
          net = e.tokens.first[:val]
          @resource_stats_collector.event :start, { group_name: 'NET', tag: net.name }, e.clock
        end
      end
      @simulator.cb_for :place, :add do |t, e|
        if e.place == 'net'
          net = e.tokens.first[:val]
          ts = e.tokens.first[:ts]
          @resource_stats_collector.event :stop, { group_name: 'NET', tag: net.name }, ts
        end
      end
    end

    def set_clock_callbacks
      @simulator.cb_for :clock, :after do |t, e|
        self.clock = e.clock
      end
    end

    def clock=(clock)
      @clock = clock
      @stats_collector.clock = clock
      @resource_stats_collector.clock = clock
    end

  end

end

module RBSim

  class Simulator
    attr_reader :clock

    # Create new simulator
    # +block+ defines new model
    # +params+ will be passed as block parameter to the model
    def initialize(params = {}, &block)
      @block = block
      @params = params
      @logger = default_logger
      @stats_collector = Statistics.new
      @resource_stats_collector = Statistics.new
      @clock = 0
    end

    def run
      simulator.run
    end

    def stop
      simulator.stop
    end

    def hlmodel
      if @hlmodel.nil?
        @hlmodel = RBSim::HLModel::Model.new
        @hlmodel.simulator = self
        Docile.dsl_eval(RBSim::DSL.new(@hlmodel), @params, &@block)
      end
      @hlmodel
    end

    def tcpn
      if @tcpn.nil?
        @tcpn = FastTCPN.read File.expand_path '../../../tcpn/model.rb', __FILE__
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
          @tcpn.add_marking_for 'data to receive', Tokens::DataQueueToken.new(process.name, process.tags)
        end


        @tcpn.add_marking_for 'routes', hlmodel.routes
        @tcpn.add_marking_for 'mapping', hlmodel.mapping


      end

      @tcpn
    end

    def simulator
      if @simulator.nil?
        @simulator = tcpn

        set_logger_callbacks
        set_stats_collector_callbacks
        set_clock_callbacks

      end
      @simulator
    end

    def logger(&block)
      @logger = block
    end

    def stats
      { application: @stats_collector, resources: @resource_stats_collector }
    end

    # FIXME: not tested!
    def stats_save(file)
      File.open file, 'w' do |f|
        f.puts Marshal.dump(stats_data)
      end
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
          message = e.binding['process'].value.serve_system_event(:log)[:args]
          @logger.call e.clock, message
        end
      end
    end

    def set_stats_collector_callbacks
      @simulator.cb_for :transition, :after do |t, e|
        if e.transition == "event::stats"
          process = e.binding['process'].value
          event = process.first_event
          params = process.serve_system_event(event)[:args]
          @stats_collector.event event.to_s.sub(/^stats_/,'').to_sym, params, e.clock
        elsif e.transition == "event::cpu"
          cpu = e.binding['CPU'].value
          @resource_stats_collector.event :start, cpu.tags.merge({ resource: 'CPU', node: cpu.node }), e.clock
        elsif e.transition == "event::cpu_finished"
          cpu = e.binding['working CPU'].value[:cpu]
          @resource_stats_collector.event :stop, cpu.tags.merge({ resource: 'CPU', node: cpu.node }), e.clock
        elsif e.transition == "transmitted"
          process = e.binding['data after net'].value.dst
          queue = e.binding['data to receive'].value
          @resource_stats_collector.event :start, queue.process_tags.merge({ resource: 'DATAQ WAIT', process: process }), e.clock
        elsif e.transition == "event::data_received"
          process = e.binding['process'].value
          @resource_stats_collector.event :stop, process.tags.merge({ resource: 'DATAQ WAIT', process: process.name }), e.clock
        elsif e.transition == "net"
          net = e.binding['net'].value
          dropped = e.binding['net'].value.drop?
          if dropped
            @resource_stats_collector.event :stats, net.tags.merge({ event: 'NET DROP', net: net.name }), e.clock
          end
        end
      end

      @simulator.cb_for :place, :remove do |t, e|
        if e.place == 'net'
          net = e.tokens.first.value
          @resource_stats_collector.event :start, net.tags.merge({ resource: 'NET', name: net.name }), e.clock
        end
      end
      @simulator.cb_for :place, :add do |t, e|
        if e.place == 'net'
          net = e.tokens.first[:val]
          ts = e.tokens.first[:ts]
          @resource_stats_collector.event :stop, net.tags.merge({ resource: 'NET', name: net.name }), ts
        elsif e.place == 'data to receive'
          queue = e.tokens.first[:val]
          process_name = queue.process_name
          process_tags = queue.process_tags
          @resource_stats_collector.event :save,
            { value: queue.length, tags: process_tags.merge({ resource: 'DATAQ LEN', process: process_name }) },
            e.tcpn.clock
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

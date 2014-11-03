# model of CPU load by application logic
# (TCPN implementation of event:cpu)
page "cpu" do
  cpu = place 'CPU'
  process = place 'process'

  transition 'event::cpu' do
    input process, :process
    input cpu, :cpu

    # Processing data on CPU.
    # args: { block: a Proc that will receive a cpu object as argument and returns computation time on this CPU }
    class EventCPU
      attr_reader :process, :cpu, :event, :delay
      def initialize(binding)
        @process = binding[:process][:val]
        @cpu = binding[:cpu][:val]
        @event = @process.serve_system_event :cpu
        @delay = @event[:args][:block].call @cpu
      end

      def process_token(clock)
        { val: @process, ts: clock + @delay }
      end

      def cpu_token(clock)
        { val: @cpu, ts: clock + @delay }
      end
    end

    output process do |binding, clock|
      EventCPU.new(binding).process_token clock
    end

    output cpu do |binding, clock|
      EventCPU.new(binding).cpu_token clock
    end

    guard do |binding, clock|
      if binding[:process][:val].has_event?(:cpu) &&
         (binding[:process][:val].node == binding[:cpu][:val].node)
        true
      else
        false
      end
    end
  end


end

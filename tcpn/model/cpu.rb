# model of CPU load by application logic
# (TCPN implementation of event:cpu)
page "cpu" do
  cpu = timed_place 'CPU', node: :node
  process = timed_place 'process', { cpu_event: [ :has_event?, :cpu ] }
  working_cpu = timed_place 'working CPU'

  # Processing data on CPU.
  # args: { block: a Proc that will receive a cpu object as argument and returns computation time on this CPU }
  class EventCPU
    attr_reader :process, :cpu, :event, :delay
    def initialize(binding)
      @process = binding['process'].value
      @cpu = binding['CPU'].value
    end

    def cpu_and_process_token(clock)
      hsh = { cpu: @cpu, process: @process }
      { ts: clock + delay, val: hsh }
    end

    private

    def delay
      event = @process.serve_system_event :cpu
      event[:args][:block].call(@cpu).to_i
    end
  end

  transition 'event::cpu' do
    input process
    input cpu


    output working_cpu do |binding, clock|
      EventCPU.new(binding).cpu_and_process_token clock
    end

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:cpu_event, true) do |process|
        marking_for['CPU'].each(:node, process.value.node) do |cpu|
          result << { 'process' => process, 'CPU' => cpu }
        end
      end
    end
=begin
    guard do |binding, clock|
      if binding[:process][:val].has_event?(:cpu) &&
         (binding[:process][:val].node == binding[:cpu][:val].node)
        true
      else
        false
      end
    end
=end

  end


  transition 'event::cpu_finished' do
    input working_cpu

    output cpu do |binding, clock|
      cpu = binding['working CPU'].value[:cpu]
      { ts: clock, val: cpu }
    end

    output process do |binding, clock|
      process = binding['working CPU'].value[:process]
      { ts: clock, val: process }
    end

  end

end

# model of CPU load by application logic
# (TCPN implementation of event:cpu)
page "cpu" do
  cpu = place 'CPU'
  process = place 'process'
  working_cpu = place 'working CPU'

  # Processing data on CPU.
  # args: { block: a Proc that will receive a cpu object as argument and returns computation time on this CPU }
  class EventCPU
    attr_reader :process, :cpu, :event, :delay
    def initialize(binding)
      @process = binding[:process][:val]
      @cpu = binding[:cpu][:val]
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
    input process, :process
    input cpu, :cpu


    output working_cpu do |binding, clock|
      EventCPU.new(binding).cpu_and_process_token clock
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


  transition 'event::cpu_finished' do
    input working_cpu, :cpu_and_process

    output cpu do |binding, clock|
      cpu = binding[:cpu_and_process][:val][:cpu]
      { ts: clock, val: cpu }
    end

    output process do |binding, clock|
      process = binding[:cpu_and_process][:val][:process]
      { ts: clock, val: process }
    end

  end

end

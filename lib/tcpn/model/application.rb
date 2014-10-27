page 'application' do
  process = place 'process'
  cpu = place 'CPU'

  transition 'event::delay_for' do
    input process, :process
    output process do |binding, clock|
      process = binding[:process][:val]
      event = process.serve_system_event :delay_for
      ts = clock + event[:args][:time]
      { val: process, ts: ts }
    end

    guard do |binding, clock|
      binding[:process][:val].has_event? :delay_for
    end
  end

  transition 'event::cpu' do
    input process, :process
    input cpu, :cpu

    class ProcessDelay
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
      ProcessDelay.new(binding).process_token clock
    end

    output cpu do |binding, clock|
      ProcessDelay.new(binding).cpu_token clock
    end

    guard do |binding, clock|
      if binding[:process][:val].has_event?(:cpu) &&
         (binding[:process][:val].node == binding[:cpu][:val].node)
        true
      else
        false
      end
    end

    transition 'event::serve_user' do
      input process, :process

      output process do |binding, clock|
        process = binding[:process][:val]
        process.serve_user_event
        process
      end

      guard do |binding, clock|
        binding[:process][:val].has_user_event?
      end
    end
  end
end

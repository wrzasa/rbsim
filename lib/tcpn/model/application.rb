page 'application' do
  process = place 'process'
  cpu = place 'CPU'
  data_to_send = place 'data to send'

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

    transition 'event::send_data' do
      input process, :process

      class ProcessSendData
        def initialize(binding)
          @process = binding[:process][:val]
          @event = @process.serve_system_event :send_data
        end

        def data_token(clock)
          # FIXME: Here return an object representing data token instead of Hash!
          # FIXME: From and To addresses on data! Solve process <-> node address translation!
          data_attributes = [ :volume, :type, :content ]
          data = @event[:args].select { |attr| data_attributes.include? attr }
          { val: data, ts: clock }
        end

        def process_token(clock)
          { val: @process, ts: clock }
        end
      end

      output process do |binding, clock|
        ProcessSendData.new(binding).process_token clock
      end

      output data_to_send do |binding, clock|
        ProcessSendData.new(binding).data_token clock
      end

      guard do |binding, clock|
        binding[:process][:val].has_event? :send_data
      end
    end

  end
end

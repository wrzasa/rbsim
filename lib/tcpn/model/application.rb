page 'application' do
  process = place 'process'
  cpu = place 'CPU'
  data_to_send = place 'data to send'
  mapping = place 'mapping'

  # Delay process execution for specified time.
  # args: { time: time for which we should wait }
  class EventDelayFor
    def initialize(binding)
      @process = binding[:process][:val]
      @event = @process.serve_system_event :delay_for
    end

    def process_token(clock)
      ts = clock + @event[:args][:time]
      { val: @process, ts: ts }
    end
  end

  transition 'event::delay_for' do
    input process, :process
    output process do |binding, clock|
      EventDelayFor.new(binding).process_token(clock)
    end

    guard do |binding, clock|
      binding[:process][:val].has_event? :delay_for
    end
  end

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

      # Sending data to anothe node.
      # args: { volume: volume of send data,
      #         type: type of send data (to use in HLModel),
      #         content: content of send data (to use in HLModel),
      #         src: TODO (source of data),
      #         dst: TODO (destination of data) }
      #
      # FIXME: We should return an object representing data token instead of Hash!
      # FIXME: From/src and To/dst addresses on data! Solve process <-> node address translation!
      class EventSendData
        def initialize(binding)
          @process = binding[:process][:val]
          @event = @process.serve_system_event :send_data
        end

        def data_token(clock)
          data_attributes = [ :volume, :type, :content ]
          data = @event[:args].select { |attr| data_attributes.include? attr }
          { val: data, ts: clock }
        end

        def process_token(clock)
          { val: @process, ts: clock }
        end
      end

      output process do |binding, clock|
        EventSendData.new(binding).process_token clock
      end

      output data_to_send do |binding, clock|
        EventSendData.new(binding).data_token clock
      end

      guard do |binding, clock|
        binding[:process][:val].has_event? :send_data
      end
    end

    transition 'event::new_process' do
      input process, :process
      input mapping, :mapping

      # Creating new process on the same node
      # args: { program: program name for new process (optional),
      #         constructor: block called as constructor of new process (adds initial events),
      #         constructor_args: args passed to the constructor }
      class EventNewProcess
        def initialize(binding)
          @process = binding[:process][:val]
          @event = @process.serve_system_event :new_process
          @new_process = @event[:args][:constructor].call @event[:args][:constructor_args]
          @mapping = binding[:mapping][:val]
          @mapping[@new_process.name] = @new_process.node
        end

        def process_tokens(clock)
          [ { ts: clock, val: @process }, { ts: clock, val: @new_process } ]
        end

        def mapping_token(clock)
          { ts: clock, val: @mapping }
        end
      end

      output process do |binding, clock|
        EventNewProcess.new(binding).process_tokens(clock)
      end

      output mapping do |binding, clock|
        EventNewProcess.new(binding).mapping_token(clock)
      end

      guard do |binding, clock|
        binding[:process][:val].has_event? :new_process
      end
    end

  end
end

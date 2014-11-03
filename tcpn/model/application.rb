page 'application' do
  process = place 'process'
  data_to_send = place 'data to send'
  mapping = place 'mapping'
  data_to_receive = place 'data to receive'

  # model of CPU load by application logic 
  sub_page "cpu.rb"

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
    # args: { to: destination process name,
    #         size: volume of send data,
    #         type: type of send data (to use in HLModel),
    #         content: content of send data (to use in HLModel) }
    class EventSendData
      def initialize(binding)
        @process = binding[:process][:val]
        @event = @process.serve_system_event :send_data
        @data = RBSim::Tokens::DataToken.new(@process.node, @process.name, @event[:args])
      end

      def data_token(clock)
        { val: @data, ts: clock }
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

  transition 'event::data_received' do
    input process, :process
    input data_to_receive, :data

    class EventDataReceived
      def initialize(binding)
        @process = binding[:process][:val]
        @data = binding[:data][:val]
        @process.register_event :data_received, @data
      end

      def process_token(clock)
        { ts: clock, val: @process }
      end
    end

    output process do |binding, clock|
      EventDataReceived.new(binding).process_token(clock)
    end

    guard do |binding, clock|
      process = binding[:process][:val]
      data = binding[:data][:val]
      process.name == data.dst
    end
  end

  transition 'event::log' do
    input process, :process

    # Log message from process
    # args: log message
    class EventLog
      def initialize(binding)
        @process = binding[:process][:val]
        @event = @process.serve_system_event :log
      end

      def process_token(clock)
        { val: @process, ts: clock }
      end
    end

    output process do |binding, clock|
      EventLog.new(binding).process_token(clock)
    end

    guard do |binding, clock|
      binding[:process][:val].has_event? :log
    end
  end

end

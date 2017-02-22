page 'application' do
  process = timed_place 'process', { first_event: :first_event, user_event: :has_user_event?, name: :name }
  data_to_send = place 'data to send'
  mapping = place 'mapping'
  data_to_receive = place 'data to receive', empty: :empty?

  # model of CPU load by application logic 
  sub_page "cpu.rb"

  # statistics
  sub_page "stats.rb"

  # new event from user (register_event statement)
  sub_page "register_event.rb"

  # Delay process execution for specified time.
  # args: { time: time for which we should wait }
  class EventDelayFor
    def initialize(binding)
      @process = binding['process'].value
      @event = @process.serve_system_event :delay_for
    end

    def process_token(clock)
      ts = clock + @event[:args][:time].to_i
      { val: @process, ts: ts }
    end
  end

  transition 'event::delay_for' do
    input process
    output process do |binding, clock|
      EventDelayFor.new(binding).process_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:first_event, :delay_for) do |p|
        result << { 'process' => p }
      end
    end
=begin
    guard do |binding, clock|
      binding[:process][:val].has_event? :delay_for
    end
=end
  end

  transition 'event::serve_user' do
    input process

    output process do |binding, clock|
      process = binding['process'].value
      process.serve_user_event
      process
    end

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:user_event, true) do |p|
        result << { 'process' => p }
      end
    end

=begin
    guard do |binding, clock|
      binding[:process][:val].has_user_event?
    end
=end
  end

  transition 'event::send_data' do
    input process

    # Sending data to anothe node.
    # args: { to: destination process name,
    #         size: volume of send data,
    #         type: type of send data (to use in HLModel),
    #         content: content of send data (to use in HLModel) }
    class EventSendData
      def initialize(bndng)
        @process = bndng['process'].value
        @event = @process.serve_system_event :send_data
        fragments = [
          @process.data_fragmentation,
          @event[:args][:size].to_i / 1500.bytes
        ].min
        fragments = 1 if fragments == 0
        @data = fragments.times.map do
          d = RBSim::Tokens::DataToken.new(self.object_id, @process.node, @process.name, @event[:args])
          d.fragments = fragments
          d
        end
      end

      def data_token(clock)
        @data.map { |d| { val: d, ts: clock } }
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

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:first_event, :send_data) do |p|
        result << { 'process' => p }
      end
    end

=begin
    guard do |binding, clock|
      binding[:process][:val].has_event? :send_data
    end
=end
  end

  transition 'event::new_process' do
    input process
    input mapping

    # Creating new process on the same node
    # args: { program: program name for new process (optional),
    #         constructor: block called as constructor of new process (adds initial events),
    #         constructor_args: args passed to the constructor }
    class EventNewProcess
      def initialize(binding)
        @process = binding['process'].value
        @event = @process.serve_system_event :new_process
        @new_process = @event[:args][:constructor].call @event[:args][:constructor_args]
        @mapping = binding['mapping'].value
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

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:first_event, :new_process) do |p|
        mapping = marking_for['mapping'].first
        result << { 'process' => p , 'mapping' => mapping}
      end
    end
=begin
    guard do |binding, clock|
      binding[:process][:val].has_event? :new_process
    end
=end
  end

  transition 'event::data_received' do
    input process
    input data_to_receive

    class EventDataReceived
      def initialize(binding)
        @process = binding['process'].value
        @queue = binding['data to receive'].value
        @data = @queue.get
        @process.enqueue_event :data_received, @data
      end

      def process_token(clock)
        { ts: clock, val: @process }
      end

      def queue_token(clock)
        { ts: clock, val: @queue }
      end
    end

    output process do |binding, clock|
      EventDataReceived.new(binding).process_token(clock)
    end

    output data_to_receive do |binding, clock|
      EventDataReceived.new(binding).queue_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['data to receive'].each(:empty, false) do |queue|
        marking_for['process'].each(:name, queue.value.process_name) do |process|
          result << { 'process' => process, 'data to receive' => queue }
        end
      end
    end

=begin
    guard do |binding, clock|
      process = binding[:process][:val]
      data = binding[:queue][:val].get process.name
      !data.nil?
    end
=end
  end

  transition 'event::log' do
    input process

    # Log message from process
    # args: log message
    class EventLog
      def initialize(binding)
        @process = binding['process'].value
        @event = @process.serve_system_event :log
      end

      def process_token(clock)
        { val: @process, ts: clock }
      end
    end

    output process do |binding, clock|
      EventLog.new(binding).process_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:first_event, :log) do |p|
        result << { 'process' => p }
      end
    end

=begin
    guard do |binding, clock|
      binding[:process][:val].has_event? :log
    end
=end
  end

end

page "register event" do
  process = timed_place 'process', { first_event: :first_event, id: :id }
  event = timed_place 'event' #, { process_id: :process_id }

  transition 'event::register_event' do
    input process

    class EventRegisterEvent
      def initialize(binding)
        @process = binding['process'].val
      end

      def process_token(clock)
        @process.serve_system_event :register_event
        { val: @process, ts: clock }
      end

      def event_token(clock)
        @e = @process.serve_system_event :register_event
        event = @e[:args][:event]
        args = @e[:args][:event_args]
        { val: RBSim::Tokens::EventToken.new(@process.id, event, args), ts: clock + @e[:args][:delay] }
      end

      def guard(clock)
        @process.has_event? :register_event
      end

    end

    output process do |binding, clock|
      EventRegisterEvent.new(binding).process_token(clock)
    end

    output event do |binding, clock|
      EventRegisterEvent.new(binding).event_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['process'].each(:first_event, :register_event) do |p|
        result << { 'process' => p }
      end
    end
=begin
    guard do |binding, clock|
      EventRegisterEvent.new(binding).guard(clock)
    end
=end
  end

  transition 'event::enqueue_event' do
    input event
    input process

    class EventEnqueueEvent
      def initialize(binding)
        @process = binding['process'].val
        @event = binding['event'].val
      end

      def process_token(clock)
        @process.enqueue_event(@event.name, @event.args)
        { val: @process, ts: clock }
      end

      def guard(clock)
        @process.id == @event.process_id
      end
    end

    output process do |binding, clock|
      EventEnqueueEvent.new(binding).process_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['event'].each do |e|
        marking_for['process'].each(:id, e.process_id) do |p|
          result << { 'process' => p, 'event' => e }
        end
      end
    end

=begin
    guard do |binding, clock|
      EventEnqueueEvent.new(binding).guard(clock)
    end
=end
  end
end

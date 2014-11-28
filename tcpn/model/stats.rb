page "stats" do
  process = timed_place 'process', { first_event: :first_event }

  # stats for process
  # args: stats tag
  class EventStats
    EvenList = [ :stats, :stats_stop, :stats_start, :stats_save ]

    def initialize(binding)
      @process = binding['process'].val
      @event_list = EventList
    end

    def process_token(clock)
      @process.serve_system_event @process.first_event
      { val: @process, ts: clock }
    end

    def guard(clock)
      @event_list.include? @process.first_event
    end

  end

  transition 'event::stats' do
    input process

    output process do |binding, clock|
      EventStats.new(binding).process_token(clock)
    end

    sentry do |marking_for, clock, result|
      EventStats::EventList.each do |e|
        p = marking_for(:first_event, e).first
        result << { 'process' => p } unless p.nil?
      end
    end

=begin
    guard do |binding, clock|
      EventStats.new(binding).guard(clock)
    end
=end
  end

end

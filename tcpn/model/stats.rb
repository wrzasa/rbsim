page "stats" do
  process = place 'process'

  # stats for process
  # args: stats tag
  class EventStats
    def initialize(binding)
      @process = binding[:process][:val]
      @event_list = [ :stats, :stats_stop, :stats_start ]
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
    input process, :process

    output process do |binding, clock|
      EventStats.new(binding).process_token(clock)
    end

    guard do |binding, clock|
      EventStats.new(binding).guard(clock)
    end
  end

end

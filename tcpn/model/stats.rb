page "stats" do
  process = place 'process'

  # stats for process
  # args: stats tag
  class EventStats
    def initialize(binding, type)
      @process = binding[:process][:val]
      @type = type
    end

    def process_token(clock)
      @event = @process.serve_system_event @type
      { val: @process, ts: clock }
    end

    def guard(clock)
      @process.has_event? @type
    end
  end

  transition 'event::stats' do
    input process, :process

    output process do |binding, clock|
      EventStats.new(binding, :stats).process_token(clock)
    end

    guard do |binding, clock|
      EventStats.new(binding, :stats).guard(clock)
    end
  end

  transition 'event::stats_start' do
    input process, :process

    output process do |binding, clock|
      EventStats.new(binding, :stats_start).process_token(clock)
    end

    guard do |binding, clock|
      EventStats.new(binding, :stats_start).guard(clock)
    end
  end

  transition 'event::stats_stop' do
    input process, :process

    output process do |binding, clock|
      EventStats.new(binding, :stats_stop).process_token(clock)
    end

    guard do |binding, clock|
      EventStats.new(binding, :stats_stop).guard(clock)
    end
  end

end

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
      catch(:found) do
        @event_list.each do |e|
          if @process.has_event? e
            @event = @process.serve_system_event e
            throw :found
          end
        end
        raise "WTF!? No event from list #{@event_list} is wating in #{@process.inspect}!"
      end
      { val: @process, ts: clock }
    end

    def guard(clock)
      not @event_list.select { |e| @process.has_event? e }.empty?
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

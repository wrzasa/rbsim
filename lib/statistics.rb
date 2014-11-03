module RBSim
  class Statistics
    attr_accessor :clock

    def initialize
      @freq_events = {}
      @duration_events = {}
      @clock = 0
    end

    def event(type, tag, time)
      if type == :stats
        @freq_events[tag] ||= []
        @freq_events[tag] << time
      else
        @duration_events[tag] ||= []
        @duration_events[tag] << { type => time }
      end
    end

    def freq
      result = {}
      @freq_events.each do |tag, events|
        result[tag] = events.count.to_f / @clock
      end
      result
    end

    def duration
      result = {}
      @duration_events.each do |tag, events|
        duration = 0
        start = nil
        events.each do |event, time|
          if !event[:start].nil? && start.nil?
            start = event[:start]
          elsif !event[:stop].nil? && !start.nil?
            duration += (event[:stop] - start)
            start = nil
          end
        end
        result[tag] = duration.to_f / @clock
      end
      result
    end

    def summary
      { frequencies: freq, durations: duration }
    end

  end
end

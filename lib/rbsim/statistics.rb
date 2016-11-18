module RBSim
  class Statistics
    UnknownStatsType = Class.new RuntimeError
    attr_accessor :clock

    def initialize
      @counter_events = {}
      @duration_events = {}
      @saved_values = {}
      @clock = 0
    end

    def event(type, params, time)
      if type == :stats
        @counter_events[params] ||= []
        @counter_events[params] << time
      elsif type == :save
        tags = params[:tags]
        value = params[:value]
        @saved_values[tags] ||= {}
        @saved_values[tags][time] ||= []
        @saved_values[tags][time] << value
      else
        raise UnknownStatsType.new(type) unless [:start, :stop].include? type
        @duration_events[params] ||= {}
        @duration_events[params][type] ||= []
        @duration_events[params][type] << time
      end
    end

    def durations(filters = {})
      return enum_for(:durations, filters) unless block_given?
      data = @duration_events.select &events_filter(filters)
      data.each do |tags, times|
        starts_and_stops = times[:start].zip times[:stop]
        starts_and_stops.each do |start, stop|
          yield tags, start, stop
        end
      end
    end

    def counters(filters = {})
      return enum_for(:counters, filters) unless block_given?
      data = @counter_events.select &events_filter(filters)
      data.each do |tags, events|
        yield tags, events
      end
    end

    def values(filters = {})
      return enum_for(:values, filters) unless block_given?
      data = @saved_values.select &events_filter(filters)
      data.each do |tags, times_and_values|
        times_and_values.each do |time, values|
          yield tags, time, values
        end
      end
    end

    private

    # generic event filter for all statistics
    def events_filter(filters)
      lambda do |tags, event_list|
        filters.reduce(true) do |acc, filter_item|
          filter_key, filter_value = filter_item;
          if filter_value.is_a? Regexp
            acc && tags.has_key?(filter_key) && tags[filter_key].to_s =~ filter_value
          else
            acc && tags[filter_key] == filter_value
          end
        end
      end
    end

  end
end

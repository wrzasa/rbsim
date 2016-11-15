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
      tag = params[:tag]
      group_name = params[:group_name] || ''
      if type == :stats
        @counter_events[params] ||= []
        @counter_events[params] << time
      elsif type == :save
        @saved_values[group_name] ||= {}
        @saved_values[group_name][tag] ||= {}
        @saved_values[group_name][tag][time] ||= []
        @saved_values[group_name][tag][time] << params[:value]
      else
        raise UnknownStatsType.new(type) unless [:start, :stop].include? type
        @duration_events[group_name] ||= {}
        @duration_events[group_name][tag] ||= {}
        @duration_events[group_name][tag][type] ||= []
        @duration_events[group_name][tag][type] << time
      end
    end

    def durations_summary
      result = {}
      @duration_events.each do |group_name, events|
        events.each do |tag, times|
          duration = 0
          times[:start].each_with_index do |start, i|
            stop = times[:stop][i]
            duration += stop - start unless stop.nil?
          end
          result[group_name] ||= {}
          result[group_name][tag] = duration
        end
      end
      result
    end

    # FIXME: not tested!
    def durations(filters = {})
      return enum_for(:durations, filters) unless block_given?
      @duration_events.each do |group_name, events|
        next if filters[:group] && group_name != filters[:group]
        events.each do |tag, times|
          next if filters[:tag] && tag != filters[:tag]
          times[:start].each_with_index do |start, i|
            stop = times[:stop][i] rescue nil
            yield group_name, tag, start, stop
          end
        end
      end
    end

    def counters(filters = {})
      return enum_for(:counters, filters) unless block_given?
      data = @counter_events.select do |tags, event_list|
        filters.reduce(true) do |acc, filter_item|
          filter_key, filter_value = filter_item;
          if filter_value.is_a? Regexp
            acc && tags.has_key?(filter_key) && tags[filter_key].to_s =~ filter_value
          else
            acc && tags[filter_key] == filter_value
          end
        end
      end
      data.each do |tags, events|
        yield tags, events
      end
    end

    # FIXME: not tested!
    def values(filters = {})
      return enum_for(:values, filters) unless block_given?
      @saved_values.each do |group_name, events|
        next if filters[:group] && group_name != filters[:group]
        events.each do |tag, time_with_values|
          next if filters[:tag] && tag != filters[:tag]
          time_with_values.each do |time, values|
            yield group_name, tag, time, values
          end
        end
      end
    end

    def values_summary
      @saved_values
    end

    def to_hash
      { counters: counters_summary, durations: durations_summary, values: values_summary }
    end

    def print
      puts "Counters"
      puts "------------------------------"
      print_stats counters_summary do |value|
        value
      end
      puts "Durations"
      puts "------------------------------"
      print_stats durations_summary do |value|
        "%6.3fs (%7.4f%%)" % [ (value.to_f.in_seconds), (value.to_f / @clock * 100) ]
      end
      puts "Values"
      puts "------------------------------"
      print_stats values_summary do |pairs|
        pairs.map { |time, value| "#{time}: #{value.inspect}" }.join ", "
      end
    end

    private 

    def print_stats(result)
      result.keys.sort{ |a,b| a.to_s <=> b.to_s}.each do |group_name|
        stats = result[group_name]
        puts "\t#{group_name}"
        stats.keys.sort{ |a,b| a.to_s <=> b.to_s}.each do |tag|
          value = stats[tag]
          puts "\t\t#{tag}\t: #{yield value}"
        end
      end
    end



  end
end

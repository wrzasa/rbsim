module RBSim
  class Statistics
    UnknownStatsType = Class.new RuntimeError
    attr_accessor :clock

    def initialize
      @counter_events = {}
      @duration_events = {}
      @clock = 0
    end

    def event(type, params, time)
      tag = params[:tag]
      group_name = params[:group_name] || ''
      if type == :stats
        @counter_events[group_name] ||= {}
        @counter_events[group_name][tag] ||= []
        @counter_events[group_name][tag] << time
      else
        raise UnknownStatsType.new(type) unless [:start, :stop].include? type
        @duration_events[group_name] ||= {}
        @duration_events[group_name][tag] ||= {}
        @duration_events[group_name][tag][type] ||= []
        @duration_events[group_name][tag][type] << time
      end
    end

    def counters
      result = {}
      @counter_events.each do |group_name, events|
        events.each do |tag, time_list|
          result[group_name] ||= {}
          result[group_name][tag] = time_list.count
        end
      end
      result
    end

    def durations
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

    def hash
      { counters: counters, durations: durations }
    end

    def print
      puts "Counters"
      puts "------------------------------"
      print_stats counters do |value|
        value
      end
      puts "Durations"
      puts "------------------------------"
      print_stats durations do |value|
        "%6.3fs (%7.4f%%)" % [ (value.to_f.in_seconds), (value.to_f / @clock * 100) ]
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

module RBSim
  class Statistics
    attr_accessor :clock

    def initialize
      @counter_events = {}
      @duration_events = {}
      @clock = 0
    end

    def event(type, params, time)
      tag = params[:tag]
      name = params[:name] || ''
      if type == :stats
        @counter_events[name] ||= {}
        @counter_events[name][tag] ||= []
        @counter_events[name][tag] << time
      else
        @duration_events[name] ||= {}
        @duration_events[name][tag] ||= []
        @duration_events[name][tag] << { type => time }
      end
    end

    def counters
      result = {}
      @counter_events.each do |name, events|
        events.each do |tag, time_list|
          result[name] ||= {}
          result[name][tag] = time_list.count
        end
      end
      result
    end

    def durations
      result = {}
      @duration_events.each do |name, events|
        events.each do |tag, events|
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
          result[name] ||= {}
          result[name][tag] = duration
        end
      end
      result
    end

    def hash
      { counters: counters, durations: durations }
    end

    def print
      puts "Counters (in relation to time)"
      puts "------------------------------"
      print_stats counters
      puts "Durations"
      puts "------------------------------"
      print_stats durations
    end

    private 

    def print_stats(result)
      result.keys.sort{ |a,b| a.to_s <=> b.to_s}.each do |name|
        stats = result[name]
        puts "\t#{name}"
        stats.keys.sort{ |a,b| a.to_s <=> b.to_s}.each do |tag|
          value = stats[tag]
          puts "\t\t#{tag}\t:\t#{value} (%.4f%%)" % (value.to_f / @clock * 100)
        end
      end
    end



  end
end

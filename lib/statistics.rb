module RBSim
  class Statistics
    attr_accessor :clock

    def initialize
      @events = {}
      @clock = 0
    end

    def event(type, tag, time)
      @events[tag] ||= []
      @events[tag] << { type => time }
    end


  end
end

# This is a base class to create RBSim based experiment
# that is able to load your model and start simulation.
# It encapsulates model, parameters and statistics
# and also all your methods used to compute simulation results.

require 'pathname'

module RBSim

  class Experiment
    attr_accessor :file, :params, :time_limit, :data_fragmentation
    attr_reader :model

    RECORD_SEPARATOR = "__ END OF RECORD __"

    def initialize(params = nil, stats = nil)
      @params, @stats = params, stats
    end

    def stats
      return @stats unless @stats.nil?
      @stats = model.stats
    end

    # Run specified model with its params
    # and collect statistics
    def run(file, params)
      read_model(file, params)
      @model.data_fragmentation = data_fragmentation unless data_fragmentation.nil?
      @model.run
    end

    # Save statistics to a file
    def save_stats(file)
      File.open file, 'a' do |f|
        f.print Marshal.dump [params, stats]
        f.print RECORD_SEPARATOR
      end
    end

    # Read statistics from a file, return Enumerator of
    # objects, each opject represents separate experiment
    def self.read_stats(file, dots = false)
      size = 0
      File.open(file) do |file|
        size = file.each_line(RECORD_SEPARATOR).count
      end

      e = Enumerator.new size do |y|
        File.open(file) do |file|
          begin
            while !file.eof?
              file.each_line(RECORD_SEPARATOR) do |line|
                print "." if dots
                params, stats = Marshal.restore line
                y << self.new(params, stats)
              end
            end
          rescue ArgumentError => e
            raise ArgumentError.new "#{caller.first} got #{e.inspect} after reading #{objects.length} objects!"
          end
        end
      end

      puts if dots
      e
    end

    def res_stats
      stats[:resources]
    end

    def app_stats
      stats[:application]
    end

    private

    def read_model(file, params)
      @file = file
      @params = params
      @model = RBSim.read file, params
      @model.tcpn.cb_for :clock, :after, &self.method(:timer)
      @model.tcpn.cb_for :clock, :after, &self.method(:time_limit_observer)
    end

    def timer(tag, event)
      @prev_seconds = 0 if @prev_seconds.nil?
      @timer_length = 0 if @timer_length.nil?

      seconds = event.clock.in_seconds.truncate
      if seconds > @prev_seconds
        print "\b"*@timer_length
        timer = "Time: #{seconds} sec."
        print timer
        @timer_length = timer.length
      end
      @prev_seconds = seconds
    end

    def time_limit_observer(tag, event)
      return if @time_limit.nil?
      if event.clock > @time_limit
        @model.stop
      end
    end

  end

end

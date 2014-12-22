# This is a base class to create RBSim based simulator
# of your model and encapsulate all parameters, statistics
# and others.

require 'pathname'

module RBSim

  class Model
    attr_accessor :file, :params
    attr_reader :model

    RECORD_SEPARATOR = "__ END OF RECORD __"

    def initialize(params = nil, stats = nil)
      @params, @stats = params, stats
    end

    def stats
      return @stats unless @stats.nil?
      @stats = model.stats_data
    end

    # Run specified model with its params
    # and collect statistics
    def run(file, params)
      read_model(file, params)
      @model.run
    end

    # Save statistics to a file
    def save_stats(file)
      File.open file, 'a' do |f|
        f.print Marshal.dump [params, stats]
        f.print RECORD_SEPARATOR
      end
    end

    # Read statistics from a file, return array of
    # objects, each opject represents separate experiment
    def self.read_stats(file, dots = false)
      objects = []
      begin
        File.open(file) do |file|
          while !file.eof?
            file.each_line(RECORD_SEPARATOR) do |line|
              print "." if dots
              params, stats = Marshal.restore line
              objects << self.new(params, stats)
            end
          end
        end
      rescue ArgumentError => e
        puts "#{caller.first} got #{e.inspect} after reading #{objects.length} objects!"
      end

      puts if dots
      objects
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
  end

end

module RBSim
  module HLModel

    class Process
      NoHandlerForUserEvent = Class.new RuntimeError
      InvalidEventType = Class.new RuntimeError
      InvalidSystemEventPassed = Class.new RuntimeError
      NoEventToServe = Class.new RuntimeError
      NotAssignedToNode = Class.new RuntimeError

      attr_reader :name, :program
      attr_accessor :node

      alias id name

      # +name+: name of this process used to assign it to a node
      # +program+: name of program running in this process (if any name was given); this is just for information
      def initialize(name, program = nil)
        @event_handlers = { data_received: generic_data_received_handler }
        @event_queue = []
        @name = name
        @program = program
      end

      # define event handler
      def on_event(event, &block)
        @event_handlers[event] = block
      end

      # event just happened
      def enqueue_event(event, args = nil)
        handler = nil # system event has no handling code defined here
                      # it must be handled by somethig external, like
                      # TCPN transition!
        unless system_event_names.include? event
          handler = @event_handlers[event]
          if handler.nil?
            raise NoHandlerForUserEvent.new(event)
          end
        end
        @event_queue << { name: event, block: handler, args: args }
      end

      # serve first event if it is a user event
      def serve_user_event
        check_if_assigned!
        if has_system_event?
          raise InvalidEventType.new("#{@event_queue.first[:name]} is not a user event!")
        end
        event = @event_queue.shift
        event[:block].call self, event[:args]
      end

      # serve first event if it is a system event
      def serve_system_event(name)
        check_if_assigned!
        unless has_event?
          raise NoEventToServe.new
        end
        unless has_event? name
          raise InvalidSystemEventPassed.new("You tried to serve: #{name}, but first in queue is: #{@event_queue.first[:name]}")
        end
        if has_user_event?
          raise InvalidEventType.new("#{@event_queue.first[:name]} is not a system event!")
        end
        event = @event_queue.shift
        { name: event[:name], args: event[:args] }
      end

      # is there a user event to serve?
      def has_user_event?
        return false unless has_event?
        return false if system_event_names.include? @event_queue.first[:name]
        true
      end

      # is there a system event to serve?
      def has_system_event?
        return false unless has_event?
        return true if system_event_names.include? @event_queue.first[:name]
        false
      end

      # is there any event to serve?
      def has_event?(name = nil)
        return false if @event_queue.empty?
        return true if name == nil
        return true if @event_queue.first[:name] == name
        false
      end

      def handlers_size
        @event_handlers.size
      end

      def event_queue_size
        @event_queue.size
      end

      # system events need special handling, by special
      # transitions, e.g. :cpu event requires a cpu token
      # :delay_for requires change in timestamp, etc.
      # handlers for system events must be implemented
      # in simulator!
      def system_event_names
        [ :cpu,  :delay_for, :send_data, :new_process, :register_event, :log, :stats_start, :stats_stop, :stats ]
      end

      # Start new process on the same node
      # used when creating new process during simulation
      def new(program = nil)
        self.class.new @node, program
      end

      private
      def check_if_assigned!
        if @node.nil?
          raise NotAssignedToNode.new("process #{@name} will not serve events until assigned to a node!")
        end
      end

      def generic_data_received_handler
        proc do |process, data|
          STDERR.puts "WARNING! Process #{process.name} on node #{process.node} received data, but has no handler defined! Define handler for event :data_received! Data packege will be dropped! Received data: #{data}"
        end
      end

    end

  end
end

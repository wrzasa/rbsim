module RBSim
  module HLModel

    class Process
      NoHandlerForUserEvent = Class.new RuntimeError
      InvalidEventType = Class.new RuntimeError
      InvalidSystemEventPassed = Class.new RuntimeError

      attr_reader :node, :program, :id

      # +node+: name of node where this process runs
      # +program+: name of program running in this process (if any name was given); this is just for information
      def initialize(node, program = nil)
        @event_handlers = {}
        @event_queue = []
        @node = node
        @program = program
        @id = self.object_id # used to identify process in TCPN, uniqe, not chaged by cloning!
      end

      # define event handler
      def with_event(event, &block)
        @event_handlers[event] = block
      end

      # event just happened
      def register_event(event, args = nil)
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
        if has_system_event?
          raise InvalidEventType.new("#{@event_queue.first[:name]} is not a user event!")
        end
        event = @event_queue.shift
        event[:block].call event[:args]
      end

      # serve first event if it is a system event
      def serve_system_event(name)
        if has_user_event?
          raise InvalidEventType.new("#{@event_queue.first[:name]} is not a system event!")
        end
        unless has_event? name
          raise InvalidSystemEventPassed.new("You tried to serve: #{name}, but first in queue is: #{@event_queue.first[:name]}")
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
        [ :cpu,  :delay_for, :send_data, :new_process, :register_event ]
      end
    end

  end
end

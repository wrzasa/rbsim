module RBSim
  module HLModel

    class Process
      NoHandlerForUserEvent = Class.new RuntimeError

      attr_reader :event_handlers, :event_queue

      def initialize
        @event_handlers = {}
        @event_queue = []
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

      # serve first user event if there is any
      def serve_user_event
        return nil if has_system_event?
        event = @event_queue.shift
        event[:block].call event[:args]
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

      # system events need special handling, by special
      # transitions, e.g. :cpu event requires a cpu token
      # :delay_for requires change in timestamp, etc.
      # handlers for system events must be implemented
      # in simulator!
      def system_event_names
        [ :cpu,  :delay_for, :send_data, :new_process ]
      end
    end

  end
end

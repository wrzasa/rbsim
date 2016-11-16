require 'rbsim/hlmodel'

module RBSim
  module Tokens

    class ProcessToken < HLModel::Process
      #include TCPN::TokenMethods
    end

    class RoutesToken < HLModel::Routes
      #include TCPN::TokenMethods
    end

    class NetToken < HLModel::Net
      #include TCPN::TokenMethods
    end

    class CPUToken < HLModel::Node::CPU
      #include TCPN::TokenMethods
    end

    class Data
      IncompleteDataDefinition = Class.new RuntimeError
      attr_reader :src, :dst, :src_node, :size, :type, :content, :id
      attr_accessor :dst_node, :route

      def initialize(node, process, opts)
        @src_node = node
        @src = process
        @dst = opts[:to]
        [ :size, :type, :content].each do |a|
          self.instance_variable_set "@#{a}".to_sym, opts[a]
        end
        if @size.nil?
          raise IncompleteDataDefinition.new("Must define size of data package!");
        end
        if @dst.nil?
          raise IncompleteDataDefinition.new("Must define destination of data package!");
        end
        @id = self.object_id
      end

      def to_s
        v = [:src, :dst, :src_node, :size, :type, :content].map do |k|
          "#{k}: #{self.send(k).inspect}"
        end.join ', '
        "{#{v}}"
      end

      def ==(o)
        return false unless o.kind_of? Data
        o.id == id
      end

      def has_next_net?
        @route.has_next_net?
      end

    end

    class DataToken < Data
      #include TCPN::TokenMethods
    end

    class DataQueue
      attr_reader :process_name, :process_tags
      def initialize(process_name, process_tags = {})
        @process_name = process_name
        @process_tags = process_tags
        @queue = []
      end

      def put(o)
        @queue << o
      end

      def get
        @queue.shift
      end

      def length
        @queue.length
      end

      def empty?
        length == 0
      end
    end

    class DataQueueToken < DataQueue
      #include TCPN::TokenMethods
    end


    class Event
      attr_reader :process_id, :name, :args
      def initialize(process_id, name, args)
        @process_id = process_id
        @name = name
        @args = args
      end
    end

    class EventToken < Event
      #include TCPN::TokenMethods
    end

  end
end

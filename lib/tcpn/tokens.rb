require 'hlmodel'
require 'tcpn'

module RBSim
  module Tokens

    class ProcessToken < HLModel::Process
      include TCPN::TokenMethods
    end


    class Data
      IncompleteDataDefinition = Class.new RuntimeError
      attr_reader :src, :dst, :src_node, :size, :type, :content
      attr_accessor :dst_node

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
      end
    end

    class DataToken < Data
      include TCPN::TokenMethods
    end
  end
end

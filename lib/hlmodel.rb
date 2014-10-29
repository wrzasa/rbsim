require 'hlmodel/infrastructure.rb'
require 'hlmodel/process.rb'
require 'hlmodel/mapping.rb'

module RBSim
  module HLModel

    Model = Struct.new :nodes, :nets, :routes, :programs, :processes, :mapping do
      def initialize(*)
        super
        self.programs = {}
        self.processes = {}
        self.mapping = Mapping.new
        self.each_pair do |attr, val|
          if val.nil?
            self.send "#{attr}=".to_sym, []
          end
        end
      end
    end

  end
end

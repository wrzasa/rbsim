require 'hlmodel/infrastructure.rb'
require 'hlmodel/process.rb'

module RBSim
  module HLModel

    Model = Struct.new :nodes, :nets, :routes, :programs, :processes do
      def initialize(*)
        super
        self.programs = {}
        self.processes = {}
        self.each_pair do |attr, val|
          if val.nil?
            self.send "#{attr}=".to_sym, []
          end
        end
      end
    end

  end
end

require 'rbsim/hlmodel/infrastructure.rb'
require 'rbsim/hlmodel/process.rb'
require 'rbsim/hlmodel/mapping.rb'

module RBSim
  module HLModel

    Model = Struct.new :nodes, :nets, :routes, :programs, :processes, :mapping do
      def initialize(*)
        super
        self.programs = {}
        self.processes = {}
        self.mapping = Mapping.new
        self.routes = Tokens::RoutesToken.new
        self.each_pair do |attr, val|
          if val.nil?
            self.send "#{attr}=".to_sym, []
          end
        end
      end
    end

  end
end

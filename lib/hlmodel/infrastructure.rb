module RBSim
  module HLModel
    Model = Struct.new :nodes, :nets, :routes do
      def initialize(*)
        super
        self.nets = {} if self.nets.nil?
        self.each_pair do |attr, val|
          if val.nil?
            self.send "#{attr}=".to_sym, []
          end
        end
      end
    end

    Node = Struct.new :name, :cpus
    class Node
      CPU = Struct.new :performance
    end

    Net = Struct.new :name, :bw, :delay
    Route = Struct.new :from, :to, :via, :twoway do
      def initialize(*)
        super
        self.twoway = false unless self.twoway
      end
    end
  end
end

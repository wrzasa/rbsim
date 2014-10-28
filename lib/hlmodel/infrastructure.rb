module RBSim
  module HLModel

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

module RBSim
  module HLModel

    Node = Struct.new :name, :cpus
    class Node
      CPU = Struct.new :performance
    end

    Net = Struct.new :name, :bw, :delay

    class Routes
      def initialize
        @routes = {}
      end

      def add(route)
        key = [route.src, route.dst]
        @routes[key] = route
        if route.twoway?
          @routes[key.reverse] = route
        end
      end

      def find(src, dst)
        route = @routes[[src, dst]]
        return nil if route.nil?
        if route.src == src
          route
        else
          route.reverse!
        end
      end

    end

    Route = Struct.new :src, :dst, :via, :twoway do

      CannotReverseOnewayRoute = Class.new RuntimeError

      def initialize(*)
        super
        self.twoway = false unless self.twoway
      end

      def next_net
        net_enum.next
      end

      def has_next_net?
        net_enum.peek
        true
      rescue StopIteration
        false
      end

      def net_enum
        @net_enum ||= self.via.each
      end

      def reverse!
        raise CannotReverseOnewayRoute unless self.twoway
        self.via = self.via.reverse
        self.src, self.dst = self.dst, self.src
        @net_enum = nil
        self
      end

      def twoway?
        twoway
      end
    end
  end
end

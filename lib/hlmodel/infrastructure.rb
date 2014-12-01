module RBSim
  module HLModel

    Node = Struct.new :name, :cpus
    class Node
      CPU = Struct.new :performance, :node
    end

    Net = Struct.new :name, :bw, :delay

    class Routes
      def initialize
        @routes = {}
      end

      def add(route)
        key = [route.src, route.dst]
        @routes[key] ||= []
        @routes[key] << route
        if route.twoway?
          @routes[key.reverse] ||= []
          @routes[key.reverse] << route
        end
      end
      alias << add

      def find(src, dst)
        routes = @routes[[src, dst]]
        return nil if routes.nil?
        route = if routes.size == 1
                  routes.first
                else
                  routes[rand(routes.size)]
                end
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
        @net_number = 0
      end

      def next_net
        raise StopIteration if @net_number >= via.length
        net = via[@net_number]
        @net_number += 1
        net
      end

      def has_next_net?
        @net_number < via.length
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

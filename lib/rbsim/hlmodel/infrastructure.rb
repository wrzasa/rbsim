module RBSim
  module HLModel

    Node = Struct.new :name, :cpus
    class Node
      CPU = Struct.new :performance, :node
    end

    class Net
      attr_reader :name, :bw, :delay, :drop

      InvalidTypeOfDropParameter = Class.new RuntimeError
      InvalidValueOfDropProbability = Class.new RuntimeError

      def initialize(name, bw, delay = 0, args = {})
        @name, @bw, @delay = name, bw, delay
        @drop = args[:drop] || 0
        unless @drop.kind_of?(Proc) || @drop.kind_of?(Numeric)
          raise InvalidTypeOfDropParameter.new(@drop.class)
        end
        if @drop.kind_of? Numeric
          if @drop > 1 || @drop < 0
            raise InvalidValueOfDropProbability.new(@drop)
          end
        end
      end

      def drop?
        return @drop.call if @drop.kind_of? Proc

        # a little optimization ;-)
        return true if @drop == 1
        return false if @drop == 0

        return rand <= @drop
      end
    end

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

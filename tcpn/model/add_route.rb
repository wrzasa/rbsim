# add route to data
# before network transmission
page 'add route' do
  RouteNotFound = Class.new RuntimeError

  data_for_network = place 'data for network'
  routes = place 'routes'
  data_with_route = place 'data with route'
  data_to_receive = place 'data to receive'

  class TCPNAddRouteToData
    def initialize(binding)
      @data = binding['data for network'].val
      @queue = binding['data to receive'].val
      @routes = binding['routes'].val
    end

    def with_route_token(clock)
      if to_self?
        nil
      else
        @data.route = route
        { ts: clock, val: @data }
      end
    end

    def to_self_token(clock)
      if to_self?
        @queue.put @data
      end
      { ts: clock, val: @queue }
    end

    private

    def to_self?
      @data.src_node == @data.dst_node
    end

    def route
      r = @routes.find @data.src_node, @data.dst_node
      if r.nil?
        raise RouteNotFound.new("from #{@data.src_node} to #{@data.dst_node}")
      end
      r
    end
  end

  transition 'add_route' do
    input data_for_network
    input routes
    input data_to_receive

    output routes

    output data_with_route do |binding, clock|
      TCPNAddRouteToData.new(binding).with_route_token(clock)
    end

    output data_to_receive do |binding, clock|
      TCPNAddRouteToData.new(binding).to_self_token(clock)
    end
  end
end


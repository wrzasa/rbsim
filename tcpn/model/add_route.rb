# add route to data
# before network transmission
page 'add route' do
  RouteNotFound = Class.new RuntimeError

  data_for_network = place 'data for network'
  routes = place 'routes'
  data_with_route = place 'data with route'
  data_to_receive = place 'data to receive', process_name: :process_name

  class TCPNAddRouteToData
    def initialize(binding)
      @data = binding['data for network'].value
      @queue = binding['data to receive'].value
      @routes = binding['routes'].value
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

    output routes do |binding, clock|
      binding['routes']
    end

    output data_with_route do |binding, clock|
      TCPNAddRouteToData.new(binding).with_route_token(clock)
    end

    output data_to_receive do |binding, clock|
      TCPNAddRouteToData.new(binding).to_self_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['data for network'].each do |data|
        marking_for['data to receive'].each(:process_name, data.value.dst) do |queue|
          routes = marking_for['routes'].first
          result << { 'data for network' => data,
                      'data to receive' => queue,
                      'routes' => routes }
        end
      end
    end
  end
end


# add route to data
# before network transmission
page 'add route' do
  RouteNotFound = Class.new RuntimeError

  data_for_network = place 'data for network'
  routes = place 'routes'
  data_with_route = place 'data with route'

  transition 'add_route' do
    input data_for_network, :data
    input routes, :routes

    output routes, :routes

    output data_with_route do |binding, clock|
      data = binding[:data][:val]
      routes = binding[:routes][:val]
      route = routes.find data.src_node, data.dst_node
      if route.nil?
        raise RouteNotFound.new("from #{data.src_node} to #{data.dst_node}")
      end
      data.route = route
      { ts: clock, val: data }
    end

  end
end


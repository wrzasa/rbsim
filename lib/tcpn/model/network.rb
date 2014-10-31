# network transmission model
page 'network' do
  data_with_route = place 'data with route'
  net = place 'net'
  data_after_net = place 'data after net'
  data_to_receive = place 'data to receive'

  transition 'net' do
    input data_with_route, :data
    input net, :net

    class TCPNNet
      def initialize(binding)
        @net = binding[:net][:val]
        @data = binding[:data][:val]
      end

      def net_token(clock)
        { ts: clock + delay, val: @net }
      end

      def data_token(clock)
        @data.route.next_net
        { ts: clock + delay, val: @data }
      end

      def guard(clock)
        @data.route.next_net == @net.name
      end

      private
      def delay
        @data.size.to_f/@net.bw.to_f
      end
    end

    output net do |binding, clock|
      TCPNNet.new(binding).net_token(clock)
    end

    output data_after_net do |binding, clock|
      TCPNNet.new(binding).data_token(clock)
    end

    guard do |binding, clock|
      TCPNNet.new(binding).guard(clock)
    end
  end

  transition 'next net' do
    input data_after_net, :data
    output data_with_route, :data

    guard do |binding, clock|
      data = binding[:data][:val]
      data.route.has_next_net?
    end
  end

  transition 'transmitted' do
    input data_after_net, :data
    output data_to_receive, :data

    guard do |binding, clock|
      data = binding[:data][:val]
      !data.route.has_next_net?
    end
  end
end

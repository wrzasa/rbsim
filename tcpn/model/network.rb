# network transmission model
page 'network' do
  data_with_route = place 'data with route'
  net = timed_place 'net', { name: :name }
  data_after_net = timed_place 'data after net', has_next_net: :has_next_net?
  data_to_receive = place 'data to receive', process_name: :process_name

  transition 'net' do
    input data_with_route
    input net

    class TCPNNet
      def initialize(binding)
        @net = binding['net'].value
        @data = binding['data with route'].value
        # make it run random drop generator code to cache drop decision for the next time
        @drop = @net.drop?
      end

      def net_token(clock)
        { ts: clock + delay, val: @net }
      end

      def data_token(clock)
        return nil if @drop
        @data.route.next_net
        { ts: clock + delay, val: @data }
      end

      def guard(clock)
        @data.route.next_net == @net.name
      end

      private
      def delay
        (@data.size.to_f / @data.fragments) / @net.bw.to_f
      end
    end

    output net do |binding, clock|
      TCPNNet.new(binding).net_token(clock)
    end

    output data_after_net do |binding, clock|
      TCPNNet.new(binding).data_token(clock)
    end

    sentry do |marking_for, clock, result|
      marking_for['data with route'].each do |data|
        next_net = data.value.route.next_net
        marking_for['net'].each(:name, next_net) do |net|
          result << { 'data with route' => data, 'net' => net }
        end
      end
    end

=begin
    guard do |binding, clock|
      TCPNNet.new(binding).guard(clock)
    end
=end
  end

  transition 'next net' do
    input data_after_net
    output data_with_route do |binding|
      binding['data after net']
    end

    sentry do |marking_for, clock, result|
      marking_for['data after net'].each(:has_next_net, true) do |data|
        result << { 'data after net' => data }
      end
    end
=begin
    guard do |binding, clock|
      data = binding['data after net'].val
      data.route.has_next_net?
    end
=end
  end

  transition 'transmitted' do
    input data_after_net
    input data_to_receive

    output data_to_receive do |binding, clock|
      queue = binding['data to receive'].value
      data = binding['data after net'].value
      queue.put data
      { ts: clock, val: queue }
    end

    sentry do |marking_for, clock, result|
      marking_for['data after net'].each(:has_next_net, false) do |data|
        marking_for['data to receive'].each(:process_name, data.value.dst) do |queue|
          result << { 'data after net' => data, 'data to receive' =>  queue }
        end
      end
    end
=begin
    guard do |binding, clock|
      data = binding[:data][:val]
      !data.route.has_next_net?
    end
=end
  end
end

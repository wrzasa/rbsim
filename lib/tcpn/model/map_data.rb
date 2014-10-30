# map data to proper destination nodes
# before network transmission
page 'map data' do
  mapping = place 'mapping'
  data_to_send = place 'data to send'
  data_for_network = place 'data for network'

  transition 'add dst node' do
    input data_to_send, :data
    input mapping, :mapping

    output mapping, :mapping

    class TCPNMapDataDestination
      def initialize(binding)
        @data = binding[:data][:val]
        @dst = @data.dst
        @mapping = binding[:mapping][:val]
        @dst_node = @mapping[@dst]
        @data.dst_node = @dst_node
      end

      def data_token(clock)
        { ts: clock, val: @data }
      end
    end

    output data_for_network do |binding, clock|
      TCPNMapDataDestination.new(binding).data_token(clock)
    end
  end
end


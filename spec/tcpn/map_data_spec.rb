require 'spec_helper'

describe "TCPN model" do

  describe "page 'map data'" do

    let :data_token do
      RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 345, type: :req, content: :anything)
    end

    let :mapping_token do
      { ts: 0, val: { child: :laptop, worker1: :node10, client: :old_comp } }
    end

    let :tcpn do
      tcpn = FastTCPN.read 'tcpn/model/map_data.rb'

      tcpn.add_marking_for 'data to send', data_token
      tcpn.add_marking_for 'mapping', mapping_token
      tcpn
    end

    it "maps data to correct node and does not touch mapping" do
      tcpn.sim
      data = tcpn.marking_for('data for network').first[:val]
      expect(data.dst_node).to eq(:node10)

      new_mapping = tcpn.marking_for('mapping').first[:val]
      # check subsequent keys with values since #== is redefined!
      mapping_token[:val].each do |k, v|
        expect(new_mapping[k]).to eq v
      end
    end

  end
end


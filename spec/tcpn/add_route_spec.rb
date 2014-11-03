require 'spec_helper'

describe "TCPN model" do

  describe "page 'add route'" do

    let :data_token do
      data = RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 345, type: :req, content: :anything)
      data.dst_node = :node02
      data
    end

    let :correct_route do
      RBSim::HLModel::Route.new :node01, :node02, [ :net01, :net02 ]
    end

    let :incorrect_route1 do
      RBSim::HLModel::Route.new :node05, :node02, [ :net04, :net03 ]
    end

    let :incorrect_route2 do
      RBSim::HLModel::Route.new :node01, :node05, [ :net02, :net05 ]
    end

    let :routes_token do
      routes = RBSim::Tokens::RoutesToken.new
      routes << incorrect_route1
      routes << correct_route
      routes << incorrect_route2
      routes
    end

    let :tcpn do
      tcpn = TCPN.read 'tcpn/model/add_route.rb'

      tcpn.add_marking_for 'data for network', data_token
      tcpn.add_marking_for 'routes', routes_token
      tcpn.add_marking_for 'data to receive', RBSim::Tokens::DataQueueToken.new
      tcpn
    end

    it "adds correct route to data" do
      TCPN.sim(tcpn).run

      new_data = tcpn.marking_for('data with route').first[:val]
      expect(new_data.route.src).to eq data_token.src_node
      expect(new_data.route.dst).to eq data_token.dst_node
      expect(tcpn.marking_for('data to receive')).not_to be_empty
    end

  end
end



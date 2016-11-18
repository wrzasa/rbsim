require 'spec_helper'

describe "TCPN model" do

  describe "page 'add route'" do

    context "route from node to self" do
      let :data_token do
        data = RBSim::Tokens::DataToken.new(6756454, :node01, :sender, to: :worker1, size: 345, type: :req, content: :anything)
        data.fragments = 1
        data.dst_node = :node01
        data
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
        routes << incorrect_route2
        routes
      end

      let :tcpn do
        tcpn = FastTCPN.read 'tcpn/model/add_route.rb'

        tcpn.add_marking_for 'data for network', data_token
        tcpn.add_marking_for 'routes', routes_token
        tcpn.add_marking_for 'data to receive', RBSim::Tokens::DataQueueToken.new(:worker1)
        tcpn
      end

      it "adds correct route to data" do
        tcpn.sim

        expect(tcpn.marking_for('data with route')).to eq([])
        expect(tcpn.marking_for('data to receive').first[:val].get).to eq(data_token)
      end

    end

  end
end




require 'spec_helper'

describe "TCPN model" do

  describe "page 'network'" do

    let :route do
      RBSim::HLModel::Route.new :node01, :node02, [ :net01, :net02, :net03 ]
    end

    let :data_token do
      data = RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 4000, type: :req, content: :anything)
      data.dst_node = :node02
      data.route = route
      data
    end

    let :tcpn do
      tcpn = TCPN.read 'lib/tcpn/model/network.rb'

      tcpn.add_marking_for 'data with route', data_token
      bw = 50
      [ :net01, :net02, :net03, :net04, :net05 ].each do |name|
        tcpn.add_marking_for 'net', RBSim::Tokens::NetToken.new(name, bw)
        bw *= 2
      end


      tcpn
    end

    before :each do
    end

    it "puts data token with correct timestamp in 'data to receive' place" do
      TCPN.sim(tcpn).run
      expect(tcpn.marking_for('data to receive').first[:val]).to eq data_token
      time = 7.0*data_token.size/200
      expect(tcpn.marking_for('data to receive').first[:ts]).to eq time
    end

    it "fires net transition correct number of times" do
      sim = TCPN.sim(tcpn)
      count = 0
      sim.cb_for :transition, :after do |t, e|
        if e.transition == 'net'
          count += 1
        end
      end
      sim.run

      expect(count).to eq(route.via.length)

    end

    it "updates timestamp of correct net tokens" do
      TCPN.sim(tcpn).run
      time = 0
      [:net01, :net02, :net03].each do |net_name|
        net = tcpn.marking_for('net').select { |net| net[:val].name == net_name }.first
        expect(net[:ts]).to eq(data_token.size/net[:val].bw + time)
        time = net[:ts]
      end
    end
  end

end


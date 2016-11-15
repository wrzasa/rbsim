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
      tcpn = FastTCPN.read 'tcpn/model/network.rb'

      tcpn.add_marking_for 'data to receive', RBSim::Tokens::DataQueueToken.new(:worker1)
      tcpn.add_marking_for 'data with route', data_token
      bw = 50
      [ :net01, :net02, :net03, :net04, :net05 ].each do |name|
        tcpn.add_marking_for 'net', RBSim::Tokens::NetToken.new(name, bw)
        bw *= 2
      end

      tcpn
    end

    it "finishes simulation with correct clock value" do
      tcpn.sim
      time = 7.0*data_token.size/200
      expect(tcpn.clock).to eq time
    end

    it "finishes simulation with data token in 'data to receive' place" do
      tcpn.sim
      expect(tcpn.marking_for('data to receive').first[:val].get).to eq data_token
    end

    it "fires net transition correct number of times" do
      count = 0
      tcpn.cb_for :transition, :before do |t, e|
        if e.transition == 'net'
          d = e.binding['data with route'].value
          count += 1
        end
      end
      tcpn.sim

      expect(count).to eq(route.via.length)

    end

    it "correctly updates timestamps of net tokens" do
      tcpn.sim
      time = 0
      [:net01, :net02, :net03].each do |net_name|
        net = tcpn.marking_for('net').select { |net| net[:val].name == net_name }.first
        expect(net[:ts]).to eq(data_token.size/net[:val].bw + time)
        time = net[:ts]
      end
    end


    describe "dropping packages" do

      let :route do
        RBSim::HLModel::Route.new :node01, :node02, [ :net01 ]
      end

      let :data_token do
        data = RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 4000, type: :req, content: :anything)
        data.dst_node = :node02
        data.route = route
        data
      end

      let :tcpn do
        tcpn = FastTCPN.read 'tcpn/model/network.rb'

        tcpn.add_marking_for 'data to receive', RBSim::Tokens::DataQueueToken.new(:worker1)
        tcpn.add_marking_for 'data with route', data_token
        tcpn.add_marking_for 'net', RBSim::Tokens::NetToken.new(:net01, 50, 0, drop)
        tcpn
      end

      describe "when #drop? returns false" do
        let(:drop) { ->{ false } }

        it "does not drop package" do
          tcpn.sim
          expect(tcpn.marking_for('data to receive').first[:val].get).to eq data_token
        end
      end

      describe "when #drop? returns true" do
        let(:drop) { ->{ true } }

        it "drops package" do
          tcpn.sim
          expect(tcpn.marking_for('data to receive').first[:val]).to be_empty
        end
      end

      describe "when #drop? returns false then true" do
        let :data_token do
          data1 = RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 4000, type: :req, content: :anything)
          data1.dst_node = :node02
          data1.route = route

          data2 = RBSim::Tokens::DataToken.new(:node01, :sender, to: :worker1, size: 4000, type: :req, content: :anything)
          data2.dst_node = :node02
          data2.route = route

          [ data1, data2 ]
        end

        let(:drop) do 
          values = [ false, true ]
          lambda do
            values.shift
          end
        end

        it "drops one package and lets one package go" do
          tcpn.sim
          expect(tcpn.marking_for('data to receive').first[:val].length).to be 1
        end

      end

    end

  end

end


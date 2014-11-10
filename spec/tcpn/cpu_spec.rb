require 'spec_helper'

describe "TCPN model" do

  describe "page 'cpu'" do

    let(:node) { :node01 }

    let(:times) { [ 100, 200, 300, 400 ] }

    let :cpu_block do
      i = 0
      proc do |cpu|
        time = times[i]
        i += 1
        i %= times.length
        time
      end
    end

    let :process_token do
      process = RBSim::Tokens::ProcessToken.new(:test_process)
      process.node = node
      process.enqueue_event :cpu, block: cpu_block
      process
    end

    let :cpu_token do
      RBSim::Tokens::CPUToken.new(1, node)
    end


    let :tcpn do
      tcpn = TCPN.read 'tcpn/model/cpu.rb'

      tcpn.add_marking_for 'process', process_token
      tcpn.add_marking_for 'CPU', cpu_token
      tcpn
    end

    it "sets correct timestamps for cpu and process tokens" do
      TCPN.sim(tcpn).run

      process_timestamp = tcpn.marking_for('process').first[:ts]
      expect(process_timestamp).to eq times.first

      cpu_timestamp = tcpn.marking_for('CPU').first[:ts]
      expect(cpu_timestamp).to eq times.first
    end

  end
end


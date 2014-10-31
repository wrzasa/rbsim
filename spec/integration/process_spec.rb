require 'spec_helper'

describe "Application process activity" do

  module ProcessActivitySpec
    class CPU
      attr_accessor :node, :performance
      def initialize(node, performance)
        @node, @performance = node, performance
      end
    end

    class CPUToken < CPU
      include TCPN::TokenMethods
    end

  end

  let :hlmodel do
    RBSim.dsl do
      new_process :worker do
        with_event :data do |volume|
          delay_for 100
          cpu do |c|
            12/c.performance
          end
          new_process :child do
            delay_for 500
            cpu do |c|
              450/c.performance
            end
            send_data to: :worker, size: 1024, type: :hi, content: 'hello!'
          end
        end
        delay_for 100
        cpu do |cpu|
          100/cpu.performance
        end
        register_event :data, 1000
      end
    end
  end


  # FIXME: marking for TCPN should be set by DSL!
  let :tcpn do
    process_token = hlmodel.processes[:worker]
    process_token.node = :node01
    cpu_token = ProcessActivitySpec::CPUToken.new(:node01, 10)
    mapping_token = { ts: 0, val: { process_token.name => process_token.node } }


    tcpn = TCPN.read 'tcpn/model/application.rb'

    tcpn.add_marking_for 'CPU', cpu_token
    tcpn.add_marking_for 'process', process_token
    tcpn.add_marking_for 'mapping', mapping_token
    tcpn
  end

  let :simulator do
    TCPN.sim tcpn
  end

  it "produces correct transition firing sequence and final TCPN marking" do
    transitions = []
    simulator.cb_for :transition, :after do |t, e|
      transitions << e.transition
    end

    simulator.run

    expect(transitions).to eq ["event::delay_for",
                               "event::cpu",
                               "event::serve_user",
                               "event::delay_for",
                               "event::cpu",
                               "event::new_process",
                               "event::delay_for",
                               "event::cpu",
                               "event::send_data"
                              ]
    # mapping token should be updated after new
    # process is created
    mapping = tcpn.marking_for('mapping').first[:val]
    expect(mapping[:child]).to eq(:node01)

    # do we have data to send token in proper place?
    data = tcpn.marking_for('data to send').first[:val]
    expect(data.dst).to eq(:worker)
  end

  it "receives data" do
    data_token = RBSim::Tokens::DataToken.new(:node01, :process01, to: :child, size: 1234)
    tcpn.add_marking_for 'data to receive', data_token
    received_data = false
    transitions = []
    simulator.cb_for :transition, :before do |t, e|
      transitions << e.transition
      if e.transition == 'event::serve_user' && e.binding[:process][:val].has_event?(:data_received)
        received_data = true
      end
    end

    simulator.run

    expect(transitions).to include("event::data_received")
    expect(received_data).to be true
  end

end

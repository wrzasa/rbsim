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
      #include TCPN::TokenMethods
    end

  end

  let :hlmodel do
    RBSim.dsl do
      new_process :worker do
        on_event :data do |volume|
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
        register_event :data, delay: 200, args: 1000
        log "a log message here"
      end
    end
  end

  let(:process_token) { hlmodel.processes[:worker] }
  let(:data_queue) { RBSim::Tokens::DataQueueToken.new(process_token.name) }

  # FIXME: marking for TCPN should be set by DSL!
  let :tcpn do
    process_token.node = :node01
    cpu_token = ProcessActivitySpec::CPUToken.new(:node01, 10)
    mapping_token = { ts: 0, val: { process_token.name => process_token.node } }


    tcpn = FastTCPN.read 'tcpn/model/application.rb'

    tcpn.add_marking_for 'CPU', cpu_token
    tcpn.add_marking_for 'process', process_token
    tcpn.add_marking_for 'mapping', mapping_token
    tcpn.add_marking_for 'data to receive', data_queue
    tcpn
  end

  it "produces correct transition firing sequence and final TCPN marking" do
    transitions = []
    tcpn.cb_for :transition, :after do |t, e|
      transitions << e.transition
    end

    tcpn.sim

    expect(transitions).to eq ["event::delay_for",
                               "event::cpu",
                               "event::cpu_finished",
                               "event::register_event",
                               "event::log",
                               "event::enqueue_event",
                               "event::serve_user",
                               "event::delay_for",
                               "event::cpu",
                               "event::cpu_finished",
                               "event::new_process",
                               "event::delay_for",
                               "event::cpu",
                               "event::cpu_finished",
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
    data = RBSim::Tokens::DataToken.new(867545, :node01, :process01, to: :child, size: 1234)
    data.fragments = 1
    data_queue.put data
    received_data = false
    transitions = []
    tcpn.cb_for :transition, :before do |t, e|
      transitions << e.transition
      if e.transition == 'event::serve_user' && e.binding['process'].value.has_event?(:data_received)
        received_data = true
      end
    end

    tcpn.sim

    expect(transitions).to include("event::data_received")
    expect(received_data).to be true
  end

end

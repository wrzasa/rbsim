require 'spec_helper'

describe "Process activity" do

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


    tcpn = TCPN.read 'lib/tcpn/model/application.rb'

    tcpn.add_marking_for 'CPU', cpu_token
    tcpn.add_marking_for 'process', process_token
    tcpn
  end

  let :simulator do
    TCPN.sim tcpn
  end

  it "produces correct transition firing sequence" do
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
                               "event::cpu"
                              ]
  end

end

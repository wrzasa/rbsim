require 'spec_helper'

describe "Network model" do

  let :model do
    RBSim.model do
      new_process :sender do
        send_data to: :receiver, size: 10, content: "Test message"
      end

      new_process :receiver do
      end

      node :sender do
        cpu 1
      end

      node :receiver do
        cpu 1
      end

      net :net01, bw: 1024, drop: 1

      put :sender, on: :sender
      put :receiver, on: :receiver
      route from: :sender, to: :receiver, via: [ :net01 ], toway: true
    end
  end

  it "checks if a packet should be dropped" do
    # for the sake of cloning we don't have the object that will
    # receive the message at the beginning of simulation
    # twice, because stats calls it too and that also counts
    #
    # http://stackoverflow.com/questions/9800992/how-to-say-any-instance-should-receive-any-number-of-times-in-rspec
    allow(RBSim::HLModel::Net).to receive(:drop?)
    allow_any_instance_of(RBSim::HLModel::Net).to receive(:drop?) { |*a| RBSim::HLModel::Net.drop? *a }

    # twice in TCPN (arc to data and arc to net) and while collecting statistics
    expect(RBSim::HLModel::Net).to receive(:drop?).exactly(3 * model.data_fragmentation) #.and_return true
    model.run
  end

end

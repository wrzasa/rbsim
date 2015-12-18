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

      net :network, bw: 1024, drop: 1

      put :sender, on: :sender
      put :receiver, on: :receiver
      route from: :sender, to: :receiver, via: [ :network ], toway: true
    end
  end

  it "checks if a packet should be dropped" do
    # for the sake of cloning we don't have the object that will
    # receive the message at the beginning of simulation
    expect_any_instance_of(RBSim::HLModel::Net).to receive(:drop?).and_return true
    model.run
  end

end

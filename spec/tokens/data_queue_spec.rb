require 'spec_helper'

describe RBSim::Tokens::DataQueue do
  it "is FIFO" do
    subject.put :asd
    subject.put :qwe
    subject.put :zxc
    expect(subject.get).to eq(:asd)
    expect(subject.get).to eq(:qwe)
    expect(subject.get).to eq(:zxc)
  end
end

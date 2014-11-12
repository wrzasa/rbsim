require 'spec_helper'

describe RBSim::Tokens::DataQueue, focus: true do
  it "is FIFO" do
    subject.put :asd
    subject.put :qwe
    subject.put :zxc
    expect(subject.get).to eq(:asd)
    expect(subject.get).to eq(:qwe)
    expect(subject.get).to eq(:zxc)
  end

  describe "collects queue lengths for processes" do
    subject do
      queue = RBSim::Tokens::DataQueueToken.new
      queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
      queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache5')
      queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
      queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache3')
      queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
      queue
    end
    it "has 3 packages for apache1" do
      expect(subject.length_for('apache1')).to eq 3
    end

    it "has 1 package for apache5" do
      expect(subject.length_for('apache5')).to eq 1
    end

    it "has 1 package for apache3" do
      expect(subject.length_for('apache3')).to eq 1
    end

    it "has no packages for apache333" do
      expect(subject.length_for('apache333')).to eq 0
    end

  end
end

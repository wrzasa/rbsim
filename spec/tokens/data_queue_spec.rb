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

  describe "collects queue lengths for processes" do
    context "when putting something to the queue" do
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

    context "when putting and getting from the queue" do
      subject do
        queue = RBSim::Tokens::DataQueueToken.new
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache0')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache2')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache2')
        queue.get
        queue.get
        queue
      end

      it "has 1 package for apache2" do
        expect(subject.length_for('apache2')).to eq 1
      end

      it "has no packages for apache0" do
        expect(subject.length_for('apache0')).to eq 0
      end
    end

  end

  describe "remembers last involved process" do
    context "when putting" do
      subject do
        queue = RBSim::Tokens::DataQueueToken.new
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache0')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache2')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
        queue
      end
      its(:last_involved_process) { should eq 'apache1' }
    end

    context "when getting" do
      subject do
        queue = RBSim::Tokens::DataQueueToken.new
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache0')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache2')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
        queue.get
        queue
      end
      its(:last_involved_process) { should eq 'apache0' }
    end
  end

end

require 'spec_helper'

describe RBSim::Tokens::DataQueue do

  let(:apache1_first)  { RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1') }
  let(:apache1_second) { RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1') }
  let(:apache1_third)  { RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1') }
  let(:apache5_first)  { RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache5') }
  let(:apache3_first)  { RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache3') }

  describe "enqueues data for each process separatelly" do
    subject do
      queue = RBSim::Tokens::DataQueueToken.new
      queue.put apache1_first
      queue.put apache5_first
      queue.put apache1_second
      queue.put apache3_first
      queue.put apache1_third
      queue
    end

    it "has 3 data packages for apache1" do
      expect(subject.get 'apache1').to eq apache1_first
      expect(subject.get 'apache1').to eq apache1_second
      expect(subject.get 'apache1').to eq apache1_third
      expect(subject.get 'apache1').to be nil
    end

    it "has 1 data package for apache5" do
      expect(subject.get 'apache5').to eq apache5_first
      expect(subject.get 'apache5').to be nil
    end

    it "has 1 data package for apache3" do
      expect(subject.get 'apache3').to eq apache3_first
      expect(subject.get 'apache3').to be nil
    end

    it "has no data packages for apache0" do
      expect(subject.get 'apache0').to be nil
    end

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
        queue.get 'apache0'
        queue.get 'apache2'
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
      its(:last_involved_queue) { should eq 'apache1' }
    end

    context "when getting" do
      subject do
        queue = RBSim::Tokens::DataQueueToken.new
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache0')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache2')
        queue.put RBSim::Tokens::DataToken.new(:node01, 'wget', size: 1024, to: 'apache1')
        queue.get 'apache0'
        queue
      end
      its(:last_involved_queue) { should eq 'apache0' }
    end
  end

end

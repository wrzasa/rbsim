require 'spec_helper'

describe RBSim::Tokens::DataQueue do
  subject { RBSim::Tokens::DataQueue.new(:apache) }

  let(:data_id) { 12332432 }
  let(:other_data_id) { 23634657 }

  let(:data1) do
    data = RBSim::Tokens::Data.new(data_id, :node01, :apache1, to: :apache, size: 1024)
    data.fragments = 3
    data
  end

  let(:data2) do
    data = RBSim::Tokens::Data.new(data_id, :node01, :apache1, to: :apache, size: 1024)
    data.fragments = 3
    data
  end

  let(:data3) do
    data = RBSim::Tokens::Data.new(data_id, :node01, :apache1, to: :apache, size: 1024)
    data.fragments = 3
    data
  end

  let(:other_data1) do
    data = RBSim::Tokens::Data.new(other_data_id, :node01, :apache1, to: :apache, size: 1024)
    data.fragments = 2
    data
  end

  let(:other_data2) do
    data = RBSim::Tokens::Data.new(other_data_id, :node01, :apache1, to: :apache, size: 1024)
    data.fragments = 2
    data
  end

  shared_examples_for "empty queue" do
    it "is empty" do
      expect(subject.empty?).to be true
    end

    it "has length 0" do
      expect(subject.length).to eq 0
    end

    it "dequeues nil" do
      expect(subject.get).to be_nil
    end
  end

  it "raises error when fragment count is not set" do
    data = RBSim::Tokens::Data.new(other_data_id, :node01, :apache1, to: :apache, size: 1024)
    expect { subject.put data }.to raise_error
  end

  describe "until all fragments arrive" do
    before :each do
      subject.put data1
      subject.put data2
      subject.put other_data1
    end

    it_behaves_like "empty queue"

  end

  describe "when all fragments arrive" do
    before :each do
      subject.put data1
      subject.put data2
      subject.put other_data1
      subject.put data3
    end

    it "is not empty" do
      expect(subject.empty?).to be false
    end

    it "has length 1" do
      expect(subject.length).to eq 1
    end

    it "dequeues data" do
      expect(subject.get.data_id).to eq data_id
    end

    describe "when data is dequeued" do
      before :each do
        subject.get
      end

      it_behaves_like "empty queue"


      describe "when another data arrives" do
        before :each do
          subject.put other_data2
        end

        it "dequeues data" do
          expect(subject.get.data_id).to eq other_data_id
        end

      end

    end
  end

end

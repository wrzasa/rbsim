require 'spec_helper'

describe RBSim::HLModel::Net do
  describe "drop probability" do
    it "defaults to 0" do
      net = RBSim::HLModel::Net.new :net01, 1024, 10
      expect(net.drop).to eq 0
    end

    it "can be 0" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, 0
      }.not_to raise_error
    end

    it "can be 1" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, 1
      }.not_to raise_error
    end

    it "can be 0.5" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, 0.5
      }.not_to raise_error
    end

    it "can be 0.3" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, 0.3
      }.not_to raise_error
    end

    it "cannot be 1.3" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, 1.3
      }.to raise_error
    end

    it "cannot be -1" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, -1
      }.to raise_error
    end

    it "can be a lambda" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, -> { true }
      }.not_to raise_error
    end

    it "can be a Proc" do
      expect {
        RBSim::HLModel::Net.new :net01, 1024, 10, Proc.new { true }
      }.not_to raise_error
    end

    describe "given as float" do
      it "drops all packets if euqlas 1" do
        net = RBSim::HLModel::Net.new :net01, 1024, 10, 1
        dropped = 100.times.reduce(0) { |a, v| net.drop? ? a + 1 : a }
        expect(dropped).to eq 100
      end

      it "drops no packets if euqlas 1" do
        net = RBSim::HLModel::Net.new :net01, 1024, 10, 0
        dropped = 100.times.reduce(0) { |a, v| net.drop? ? a + 1 : a }
        expect(dropped).to eq 0
      end

      it "drops half of the packets if euqlas 0.5" do
        net = RBSim::HLModel::Net.new :net01, 1024, 10, 0.5
        dropped = 1000.times.reduce(0) { |a, v| net.drop? ? a + 1 : a }
        expect(dropped).to be_within(100).of(500)
      end

    end

    describe "given as lambda" do
      describe "if true" do
        it "drops packet" do
          net = RBSim::HLModel::Net.new :net01, 1024, 10, -> { true }
          expect(net.drop?).to be true
        end
      end

      describe "if false" do
        it "does not drop packet" do
          net = RBSim::HLModel::Net.new :net01, 1024, 10, -> { false }
          expect(net.drop?).to be false
        end
      end

    end
  end
end

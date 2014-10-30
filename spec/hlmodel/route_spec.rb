require 'spec_helper'

describe "HLModel::Route" do

    subject { RBSim::HLModel::Route.new :node01, :node02, [ :net01, :net02 ] }

    describe "#next_net" do
      it "iterates over subsequent net segments" do
        expect(subject.next_net).to eq :net01
        expect(subject.next_net).to eq :net02
        expect{ subject.next_net }.to raise_error StopIteration
      end
    end

    describe "#has_next_net?" do
      it "is true if there are more nets to go" do
        expect(subject.has_next_net?).to be true
      end

      it "is false it there are no more nets to go" do
        2.times { subject.next_net }
        expect(subject.has_next_net?).to be false
      end
    end

    describe "#reverse!" do
      context "twoway route" do
        subject { RBSim::HLModel::Route.new :node01, :node02, [ :net01, :net02 ], true }
        it "is reversed" do
          src = subject.src
          dst = subject.dst
          subject.reverse!
          expect(subject.src).to eq dst
          expect(subject.dst).to eq src
          expect(subject.next_net).to eq :net02
          expect(subject.next_net).to eq :net01
        end
      end
      context "oneway route" do
        subject { model.routes[0] }
        it "raises error" do
          expect{ subject.reverse! }.to raise_error
        end
      end
    end

end

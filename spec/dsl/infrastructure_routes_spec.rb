require 'spec_helper'

describe "RBSim#dsl" do
  context "model with routes" do

    let :model do
      RBSim.dsl do

        route from: :node01, to: :node02, via: [ :net01, :net02 ]
        route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: true
        route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: :true

      end
    end

    it "has three routes" do
      expect(model.routes.size).to eq 3
    end

    describe "has first route" do
      subject { model.routes.first }
      it "from :node01" do
        expect(subject.from).to eq :node01
      end
      it "to :node02" do
        expect(subject.to).to eq :node02
      end
      it "via net01 and net02" do
        expect(subject.via).to eq [:net01, :net02]
      end
    end

    describe "has second route" do
      subject { model.routes[1] }
      it "from node04" do
        expect(subject.from).to eq :node04
      end
      it "to node05" do
        expect(subject.to).to eq :node05
      end
      it "via net07 and net01" do
        expect(subject.via).to eq [:net07, :net01]
      end
      it "twoway" do
        expect(subject.twoway).to be true
      end
    end

    describe "has third route" do
      subject { model.routes[2] }
      it "twoway" do
        expect(subject.twoway).to be true
      end
    end

  end
end

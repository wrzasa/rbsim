require 'spec_helper'

describe "HLModel::Routes" do

  let(:routes) { RBSim::HLModel::Routes.new }

  let(:oneway) { RBSim::HLModel::Route.new :node01, :node02, [ :net01, :net02 ] }
  let(:twoway) { RBSim::HLModel::Route.new :node07, :node08, [ :net07, :net08 ], true }

  describe "with oneway route" do
    subject { routes.add oneway; routes }
    it "finds the route" do
      expect(subject.find(:node01, :node02)).to eq oneway
    end
    it "does not find reverse route" do
      expect(subject.find(:node02, :node01)).to be nil
    end
  end

  describe "with twoway route" do
    subject { routes.add twoway; routes }
    it "finds the route" do
      expect(subject.find(:node07, :node08)).to eq twoway
    end
    it "finds reverse route" do
      expect(subject.find(:node08, :node07)).to eq twoway.reverse!
    end
  end

  describe "multiple routes for same endpoints" do
    let(:oneway_alternative) { RBSim::HLModel::Route.new :node01, :node02, [ :net05, :net06 ] }
    subject do
      routes.add oneway
      routes.add oneway_alternative
      routes
    end

    # FIXME: how to test that it is random?
    it "finds one of alternative routes" do
      expect([oneway, oneway_alternative]).to include(subject.find :node01, :node02)
    end
  end

end

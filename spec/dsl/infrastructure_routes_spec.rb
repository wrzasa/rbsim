require 'spec_helper'

describe "RBSim#dsl" do
  context "model with routes" do

    let :model do
      RBSim.dsl do

        route from: :node01, to: :node02, via: [ :net01, :net02 ]
        route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: true
        route from: :node06, to: :node07, via: [ :net07, :net01 ], twoway: :true

      end
    end

    subject { model.routes }

    it "has route from :node01 to :node02" do
      expect(subject.find :node01, :node02).not_to be nil
    end

    it "has no route from :node02 to :node01" do
      expect(subject.find :node02, :node01).to be nil
    end

    it "has route from :node04 to :node05" do
      expect(subject.find :node04, :node05).not_to be nil
    end

    it "has route from :node05 to :node04" do
      expect(subject.find :node05, :node04).not_to be nil
    end

    it "has route from :node06 to :node07" do
      expect(subject.find :node06, :node07).not_to be nil
    end

    it "has route from :node07 to :node06" do
      expect(subject.find :node07, :node06).not_to be nil
    end


  end
end

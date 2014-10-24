require 'spec_helper'

describe 'RBSim#dsl' do
  context "model with two nets" do

    let(:model) do
     RBSim.dsl do

      net :net01, bw: 100, delay: 10
      net :net02, bw: 1000, delay: 20

     end
    end

    it "has two nets" do
      expect(model.nets.size).to eq 2
    end

    it "has net called :net01" do
      expect(model.nets.first.name).to eq :net01
    end
    context "net called :net01" do
      subject { model.nets.first }
      its(:bw) { should eq(100) }
      its(:delay) { should eq(10) }
    end

    it "has net called :net02" do
      expect(model.nets[1].name).to eq :net02
    end
    context "net called :net02" do
      subject { model.nets[1] }
      its(:bw) { should eq(1000) }
      its(:delay) { should eq(20) }
    end
  end

end

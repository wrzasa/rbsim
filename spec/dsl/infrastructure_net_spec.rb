require 'spec_helper'

describe 'RBSim#dsl' do
  context "model with two nets" do

    let(:model) do
     RBSim.dsl do

      net :net01, bw: 100, delay: 10
      net :net02, bw: 1000, delay: 20

     end
    end

    it "has two nets"

    it "has net called :net01"
    context "net called :net01" do
      subject { model.nets[:net01] }
      its(:bw) { should eq(100) }
      its(:delay) { should eq(10) }
    end

    it "has net called :net02"
    context "net called :net02" do
      subject { model.nets[:net02] }
      its(:bw) { should eq(1000) }
      its(:delay) { should eq(20) }
    end
  end

end

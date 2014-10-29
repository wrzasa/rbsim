require 'spec_helper.rb'

describe 'RBSim#dsl' do

  context "with mapping" do

    let(:model) do
      RBSim.dsl do

        put :clinet, on: :node01
        put process: :worker1, on: :node01
        put on: :node02, process: :worker2

      end
    end

    it "has :client on :node01" do
      expect(model.mapping[:client]).to eq :node01
    end

    it "has :worker1 on :node01" do
      expect(model.mapping[:worker1]).to eq :node01
    end

    it "has :worker2 on :node02" do
      expect(model.mapping[:worker2]).to eq :node02
    end

  end
end

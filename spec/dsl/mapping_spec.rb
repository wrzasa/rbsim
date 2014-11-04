require 'spec_helper.rb'

describe 'RBSim#dsl' do

  context "with mapping" do

    let(:model) do
      RBSim.dsl do

        put :client, on: :node01
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

  context "with mapping without node" do
    it "raises error" do
      expect do
        RBSim.dsl do
          put :client
        end
      end.to raise_error RuntimeError
    end
  end

  context "with mapping without process" do
    it "raises error" do
      expect do
        RBSim.dsl do
          put nil, on: :node01
        end
      end.to raise_error RuntimeError
    end
  end

  context "with mapping defined by Hash without process" do
    it "raises error" do
      expect do
        RBSim.dsl do
          put on: :node01
        end
      end.to raise_error RuntimeError
    end
  end

  context "with mapping defined by Hash without node" do
    it "raises error" do
      expect do
        RBSim.dsl do
          put process: :client
        end
      end.to raise_error RuntimeError
    end
  end
end

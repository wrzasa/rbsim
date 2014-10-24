require 'spec_helper'

describe "RBSim#dsl" do
  context "model with one empty node" do
    let(:model) do
      RBSim.dsl do
        node :worker do
        end
      end
    end

    it "has one node" do
      expect(model.nodes.size).to eq(1)
    end

    it "has node called :worker" do
      expect(model.nodes.first.name).to eq(:worker)
    end

    it "has node with no CPUs" do
      expect(model.nodes.first.cpus.size).to eq(0)
    end

  end

  context "model with nodes and CPUs" do
    let(:model) do
      RBSim.dsl do

        node :worker1 do
          cpu 1000
          cpu 2000
        end
        node :worker2 do
          cpu 200
        end

      end
    end

    it "has two nodes" do
      expect(model.nodes.size).to eq 2
    end

    it "has first node called :worker1" do
      expect(model.nodes.first.name).to eq :worker1
    end

    it "has first node with two cpus" do
      expect(model.nodes.first.cpus.size).to eq 2
    end

    it "has first node with first cpu with performance 1000" do
      expect(model.nodes.first.cpus.first.performance).to eq 1000
    end


    it "has first node with second cpu with performance 2000" do
      expect(model.nodes.first.cpus[1].performance).to eq 2000
    end

    it "has second node called :worker2" do
      expect(model.nodes[1].name).to eq :worker2
    end

    it "has second node with cpu with performance 200" do
      expect(model.nodes[1].cpus.first.performance).to eq 200
    end

  end

end

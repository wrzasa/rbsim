require 'spec_helper.rb'

describe 'RBSim#dsl' do

  shared_examples 'process defined' do

    it "has one process" do
      expect(model.processes.size).to eq(1)
    end

    it "has process :sender1" do
      expect(model.processes[:sender1]).not_to be_nil
    end
  end

  context "with processes defined by block" do

    let(:model) do
      RBSim.dsl do

        new_process :sender1 do
          delay_for time: 100
          cpu do |cpu|
            10000/cpu.performance
          end
        end

      end
    end

    include_examples 'process defined'

  end

  context "with processes defined by program" do
    let(:model) do
      RBSim.dsl do
        program :sender1_prg do |args|
          delay_for time: args[:time]
          cpu do |cpu|
            args[:volume]/cpu.performance
          end
        end
        new_process :sender1, program: :sender1_prg, args: { time: 100, volume: 10000 }
      end
    end

    include_examples 'process defined'

  end

end

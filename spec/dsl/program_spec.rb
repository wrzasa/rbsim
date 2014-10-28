require 'spec_helper.rb'

describe 'RBSim#dsl' do

  context "with two programs" do

    let(:model) do
      RBSim.dsl do

        program :waiter do |time|
          delay_for time: time
        end

        program :worker do |volume|
          cpu do |cpu|
            volume * volume / cpu.performance
          end
        end

      end
    end

    it "has two programs" do
      expect(model.programs.size).to eq(2)
    end

    it "has program called :waiter" do
      expect(model.programs[:waiter]).not_to be_nil
    end

    it "has program called :volume" do
      expect(model.programs[:worker]).not_to be_nil
    end

  end
end

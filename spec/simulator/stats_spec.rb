require 'spec_helper'

describe RBSim::Simulator do
  describe "statistics" do
    let :model do
      RBSim.model do
        new_process :worker do
          stats_start :work
          delay_for 200
          stats_stop :work
          delay_for 100
          stats :wait
          delay_for 100
          stats :wait
        end

        node :n1 do
          cpu 100
        end

        put :worker, on: :n1

      end
    end

    it "sends start_event message to Statistisc" do
      expect_any_instance_of(RBSim::Statistics).to receive(:start_event).with(:work)
      model.run
    end

    it "sends stop_event message to Statistisc" do
      expect_any_instance_of(RBSim::Statistics).to receive(:stop_event).with(:work)
      model.run
    end

    it "sends hit_event message to Statistisc" do
      expect_any_instance_of(RBSim::Statistics).to receive(:hit_event).with(:wait).twice
      model.run
    end

  end

end


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

    it "registers events in Statistisc" do
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats_start, :work, 0).once
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats_stop, :work, 200)
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats, :wait, 300)
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats, :wait, 400)
      model.run
    end

  end

end


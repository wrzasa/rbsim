require 'spec_helper'

describe RBSim::Simulator do
  describe "statistics" do
    let :model do
      RBSim.model do
        new_process :worker do
          stats_start :work, 'worker'
          delay_for 200
          stats_stop :work, 'worker'
          delay_for 100
          stats :wait, 'worker'
          delay_for 100
          stats :wait, 'worker'
          stats_save 31415, :queue_length, 'worker'
        end

        node :n1 do
          cpu 100
        end

        put :worker, on: :n1

      end
    end

    it "registers events in Statistisc" do
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:start, {tag: :work, group_name: 'worker'}, 0).once
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stop, {tag: :work, group_name: 'worker'}, 200)
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats, {tag: :wait, group_name: 'worker'}, 300)
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:stats, {tag: :wait, group_name: 'worker'}, 400)
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:save, {value: 31415, tag: :queue_length, group_name: 'worker'}, 400)
      model.run
    end

  end

end


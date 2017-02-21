require 'spec_helper'

describe RBSim::Simulator do
  describe "statistics" do
    let :model do
      RBSim.model do
        new_process :worker do
          stats_start tag: :work, group_name: 'worker'
          delay_for 200
          stats_stop tag: :work, group_name: 'worker'
          delay_for 100
          stats tag: :wait, group_name: 'worker'
          delay_for 100
          stats tag: :wait, group_name: 'worker'
          stats_save 31415, tag: :queue_length, group_name: 'worker'
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
      expect_any_instance_of(RBSim::Statistics).to receive(:event).with(:save, {value: 31415, tags: { tag: :queue_length, group_name: 'worker'} }, 400)
      model.run
    end

    describe "net dropping packages" do
      let :model do
        RBSim.model do
          new_process :sender do
            10.times { send_data to: :receiver, size: 10, content: "Test message" }
          end

          new_process :receiver do
          end

          node :sender do
            cpu 1
          end

          node :receiver do
            cpu 1
          end

          net :net01, bw: 1024, drop: drop

          put :sender, on: :sender
          put :receiver, on: :receiver
          route from: :sender, to: :receiver, via: [ :net01 ], toway: true
        end
      end

      describe "when dropping" do
        let(:drop) { 1 }

        it "counts dropped" do

          allow(RBSim::Statistics).to receive(:dropped_stats)
          allow_any_instance_of(RBSim::Statistics).to receive(:event) do |*a|
            if a[1..-2] == [:stats, {net: :net01, event: 'NET DROP'}]
              RBSim::Statistics.dropped_stats
            end
          end
          expect(RBSim::Statistics).to receive(:dropped_stats).exactly(10 * model.data_fragmentation).times
          model.run
        end
      end

      describe "when not dropping" do
        let(:drop) { 1 }

        it "counts dropped" do
          expect_any_instance_of(RBSim::Statistics).not_to receive(:event).with(:stats, 
                                                                            {tag: :net01, 
                                                                             group_name: 'NET DROP'})
          model.run
        end
      end
    end

  end

end


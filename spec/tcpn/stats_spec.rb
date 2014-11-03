require 'spec_helper'

describe "TCPN model" do

  describe "page 'stats'" do

    let :process_token do
      process = RBSim::Tokens::ProcessToken.new(:test_process)
      process.node = :node01
      process.register_event stats_event, stats_tag
      process
    end

    let :tcpn do
      tcpn = TCPN.read 'tcpn/model/stats.rb'

      tcpn.add_marking_for 'process', process_token
      tcpn
    end

    let :sim do
      TCPN.sim(tcpn)
    end

    describe ":stats event" do
      let(:stats_event) { :stats }
      let(:stats_tag) { :work }

      it "is served" do
        served = false
        args = nil
        sim.cb_for :transition, :after do |t, e|
          if e.transition == 'event::stats'
            served = true
            args = e.binding[:process][:val].serve_system_event(:stats)[:args]
          end
        end

        sim.run

        expect(served).to be true
        expect(args).to eq(stats_tag)

      end
    end

    describe ":stats_start event" do
      let(:stats_event) { :stats_start }
      let(:stats_tag) { :doing }

      it "is served" do
        served = false
        args = nil
        sim.cb_for :transition, :after do |t, e|
          if e.transition == 'event::stats_start'
            served = true
            args = e.binding[:process][:val].serve_system_event(:stats_start)[:args]
          end
        end

        sim.run

        expect(served).to be true
        expect(args).to eq(stats_tag)

      end
    end

    describe ":stats_stop event" do
      let(:stats_event) { :stats_stop }
      let(:stats_tag) { :doing }

      it "is served" do
        served = false
        args = nil
        sim.cb_for :transition, :after do |t, e|
          if e.transition == 'event::stats_stop'
            served = true
            args = e.binding[:process][:val].serve_system_event(:stats_stop)[:args]
          end
        end

        sim.run

        expect(served).to be true
        expect(args).to eq(stats_tag)

      end
    end

  end
end




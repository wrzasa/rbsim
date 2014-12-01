require 'spec_helper'

describe "TCPN model" do

  describe "page 'stats'" do

    let :process_token do
      process = RBSim::Tokens::ProcessToken.new(:test_process)
      process.node = :node01
      process.enqueue_event stats_event, event_params
      process
    end

    let(:event_params) { { tag: stats_tag, group_name: stats_group_name } }

    let :tcpn do
      tcpn = FastTCPN.read 'tcpn/model/stats.rb'

      tcpn.add_marking_for 'process', process_token
      tcpn
    end

    let(:stats_group_name) { 'apache' }

    shared_examples "is served" do
      it "is served" do
        served = false
        args = nil
        tcpn.cb_for :transition, :after do |t, e|
          if e.transition == 'event::stats'
            served = true if e.binding['process'].value.has_event?(stats_event)
            args = e.binding['process'].value.serve_system_event(stats_event)[:args]
          end
        end

        tcpn.sim

        expect(served).to be true
        expect(args).to eql(event_params)
      end
    end

    describe ":stats event" do
      let(:stats_event) { :stats }
      let(:stats_tag) { :work }

      include_examples 'is served'
    end

    describe ":stats_start event" do
      let(:stats_event) { :stats_start }
      let(:stats_tag) { :doing }

      include_examples 'is served'
    end

    describe ":stats_stop event" do
      let(:stats_event) { :stats_stop }
      let(:stats_tag) { :doing }

      include_examples 'is served'
    end

    describe ":stats_save event" do
      let(:stats_event) { :stats_save }
      let(:stats_tag) { :doing }
      let(:event_value) { 2345 }
      let(:event_params) { { value: event_value, tag: stats_tag, group_name: stats_group_name } }

      include_examples 'is served'
    end

  end
end




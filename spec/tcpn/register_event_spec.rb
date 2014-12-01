require 'spec_helper'

describe "TCPN model" do

  describe "page 'register event'" do

    let :process_token do
      process = RBSim::Tokens::ProcessToken.new(:test_process)
      process.node = :node01
      process.enqueue_event :register_event, { event: :data, delay: 10, event_args: 1024 }
      process.on_event :data do
      end
      process
    end

    let :tcpn do
      tcpn = FastTCPN.read 'tcpn/model/register_event.rb'

      tcpn.add_marking_for 'process', process_token
      tcpn
    end

    it "enqueues event in specified time" do
      register_event_fired = false
      enqueue_event_fired = false
      tcpn.cb_for :transition, :after do |t, e|
        if e.transition == 'event::register_event'
          register_event_fired = true
        elsif e.transition == 'event::enqueue_event'
          enqueue_event_fired = true
        end
      end

      tcpn.sim

      expect(register_event_fired).to be true
      expect(enqueue_event_fired).to be true

      process_timestamp = tcpn.marking_for('process').first[:ts]
      expect(process_timestamp).to eq(10)

      process = tcpn.marking_for('process').first[:val]
      expect(process.has_event? :data).to be true
    end

   end
end


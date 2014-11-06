require 'spec_helper'

describe RBSim::Simulator do
  describe "#logger" do
    let :model do
      RBSim.model do
        new_process :worker do
          log "start"
          delay_for 20.seconds
          log "stop"
        end

        node :n1 do
          cpu 100.miliseconds
        end

        put :worker, on: :n1

      end
    end

    it "logs to default logger" do
      expect { model.run }.to output("0.000: start\n20.000: stop\n").to_stdout
    end

    it "logs to custom logger" do
      logs = []
      model.logger do |clock, message|
        logs << { time: clock, message: message }
      end
      model.run
      expect(logs).to eq [ {time: 0, message: "start" }, {time: 20.seconds, message: "stop"} ]
    end
  end
end

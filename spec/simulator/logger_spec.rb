require 'spec_helper'

describe RBSim::Simulator do
  describe "#logger" do
    let :model do
      RBSim.model do
        new_process :worker do
          log "start"
          delay_for 200
          log "stop"
        end

        node :n1 do
          cpu 100
        end

        put :worker, on: :n1

      end
    end

    it "logs to default logger" do
      expect { model.run }.to output("0: start\n200: stop\n").to_stdout
    end

    it "logs to custom logger" do
      logs = []
      model.logger do |clock, message|
        logs << { time: clock, message: message }
      end
      model.run
      expect(logs).to eq [ {time: 0, message: "start" }, {time: 200, message: "stop"} ]
    end
  end
end

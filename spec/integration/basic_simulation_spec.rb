require 'spec_helper'

describe "Basic simulation example" do
  let :model do

    RBSim.model do

      program :wget do |opts|
        sent = 0
        on_event :send do
          cpu do |cpu|
            150/cpu.performance
          end
          send_data to: opts[:target], size: 1024, type: :request, content: sent
          sent += 1
          delay_for 5*rand
          register_event :send if sent < opts[:count]
        end

        on_event :data_received do |data|
          #log "Got data #{data} in process #{process.name}"
          stats :request_served, process.name
        end

        register_event :send
      end

      program :apache do
        log "apache starting"
        on_event :data_received do |data|
          stats_start :apache, process.name
          cpu do |cpu|
            100*data.size*rand / cpu.performance
          end
          send_data to: data.src, size: data.size * 10, type: :response, content: data.content
          stats_stop :apache, process.name
        end
      end

      node :desktop do
        cpu 100
      end

      node :gandalf do
        cpu 1400
      end

      new_process :client1, program: :wget, args: { target: :server, count: 10 }
      new_process :client2, program: :wget, args: { target: :server, count: 10 }
      new_process :server, program: :apache, args: 'apache1'

      net :net01, bw: 1024
      net :net02, bw: 510

      route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true

      put :server, on: :gandalf
      put :client1, on: :desktop
      put :client2, on: :desktop

    end
  end

  it "serves all requests" do
    expect{ model.run }.to output("0.000: apache starting\n").to_stdout
    p model.stats_summary
    expect(model.stats_summary[:application][:counters][:client1][:request_served]).to eq 10
    expect(model.stats_summary[:application][:counters][:client2][:request_served]).to eq 10
  end
end

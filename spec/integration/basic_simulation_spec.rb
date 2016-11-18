require 'spec_helper'

describe "Basic simulation example" do
  let :model do

    m = RBSim.model do

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
          stats tag: :request_served, group_name: process.name
        end

        register_event :send
      end

      program :apache do
        log "apache starting"
        on_event :data_received do |data|
          stats_start tag: :apache, group_name: process.name
          cpu do |cpu|
            100*data.size*rand / cpu.performance
          end
          send_data to: data.src, size: data.size * 10, type: :response, content: data.content
          stats_stop tag: :apache, group_name: process.name
        end
      end

      node :desktop do
        cpu 100, tags: { custom_tag: 'cpu_name1' }
      end

      node :gandalf do
        cpu 1400, tags: { custom_tag: 'cpu_name2' }
      end

      new_process :client1, program: :wget, args: { target: :server, count: 10 }, tags: { kind: :client }
      new_process :client2, program: :wget, args: { target: :server, count: 10 }, tags: { kind: :client }
      new_process :server, program: :apache, args: 'apache1', tags: { kind: :server }

      net :net01, bw: 1024, tags: { custom_tag: 'name1' }
      net :net02, bw: 510, tags: { custom_tag: 'name2' }

      route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true

      put :server, on: :gandalf
      put :client1, on: :desktop
      put :client2, on: :desktop

    end

    m.data_fragmentation = 2
    m
  end

  it "serves all requests" do
    expect{ model.run }.to output("0.000: apache starting\n").to_stdout
    expect(model.stats[:application].counters(group_name: :client1, tag: :request_served).to_h.values.flatten.size).to eq 10
    expect(model.stats[:application].counters(group_name: :client2, tag: :request_served).to_h.values.flatten.size).to eq 10
  end

  it "saves resource stats with tags" do
    model.run
    expect(model.stats[:resources].durations(resource: 'NET', custom_tag: 'name1').to_a).not_to be_empty
    expect(model.stats[:resources].durations(resource: 'NET', custom_tag: 'name2').to_a).not_to be_empty
    expect(model.stats[:resources].durations(resource: 'CPU', custom_tag: 'cpu_name1').to_a).not_to be_empty
    expect(model.stats[:resources].durations(resource: 'CPU', custom_tag: 'cpu_name2').to_a).not_to be_empty
    expect(model.stats[:resources].durations(resource: 'DATAQ WAIT', kind: :client).to_a).not_to be_empty
    expect(model.stats[:resources].durations(resource: 'DATAQ WAIT', kind: :server).to_a).not_to be_empty
  end
end

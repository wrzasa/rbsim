require 'spec_helper'

# Test behavior of HLModel::Process created with
# DSL new_process statement
describe "HLModel::Process created with DSL#new_process" do

  let :model do
    RBSim.dsl do
      new_process :worker do
        with_event :data do |volume|
          delay_for 200
          cpu do |c|
            20/c.performance
          end
        end
        delay_for 100
        cpu do |cpu|
          100/cpu.performance
        end
        register_event :data, 1000
      end
    end
  end

  let :process do
    p = model.processes[:worker]
    p.node = :node01
    p
  end

  class CPU
    def performance
      20
    end
  end

  it "has correct behavior" do
    event = process.serve_system_event :delay_for
    expect(event).to eq({name: :delay_for, args: { time: 100 }})

    event = process.serve_system_event :cpu
    expect(event[:name]).to eq(:cpu)
    # CPU time computed for specified CPU
    expect(event[:args][:block].call CPU.new).to eq(5)

    p = process.serve_user_event
    expect(p).to eq(process) # returns modified process
    expect(process.event_queue_size).to eq(2)

    # Events created by the above user event follow:

    event = process.serve_system_event :delay_for
    expect(event).to eq({name: :delay_for, args: { time: 200 }})

    event = process.serve_system_event :cpu
    expect(event[:name]).to eq(:cpu)
    # CPU time computed for specified CPU
    expect(event[:args][:block].call CPU.new).to eq(1)
  end

end

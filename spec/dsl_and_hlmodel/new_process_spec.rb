 require 'spec_helper'
 require 'pry'

# Test behavior of HLModel::Process created with
# DSL new_process statement
describe "HLModel::Process created with DSL#new_process" do

  let :model do
    RBSim.dsl do
      new_process :worker do
        stats_start :work, 'worker1'
        on_event :data do |volume|
          delay_for 200
          cpu do |c|
            20/c.performance
          end
        end
        delay_for 100
        stats_stop :work, 'worker1'
        stats :doing_something, 'worker1'
        cpu do |cpu|
          100/cpu.performance
        end
        new_process :child do
          delay_for 400
        end
        register_event :data, args: 1000
        send_data to: :child, size: 1024, type: :hello, content: "Hello!"
        log "finished main, will serve events"
      end
    end
  end

  let :process do
    p = model.processes[:worker]
    p.node = :node01
    p
  end

  module NewProcessSpec
    class CPU
      def performance
        20
      end
    end
  end

  it "has correct behavior" do
    expect(model.processes.size).to eq(1)

    event = process.serve_system_event :stats_start
    expect(event).to eq({name: :stats_start, args: { tag: :work, group_name: 'worker1'} })

    event = process.serve_system_event :delay_for
    expect(event).to eq({name: :delay_for, args: { time: 100 }})

    event = process.serve_system_event :stats_stop
    expect(event).to eq({name: :stats_stop, args: { tag: :work, group_name: 'worker1' } })

    event = process.serve_system_event :stats
    expect(event).to eq({name: :stats, args: { tag: :doing_something, group_name: 'worker1' } })

    event = process.serve_system_event :cpu
    expect(event[:name]).to eq(:cpu)
    # CPU time computed for specified CPU
    expect(event[:args][:block].call NewProcessSpec::CPU.new).to eq(5)

    # new process
    event = process.serve_system_event :new_process
    new_process = event[:args][:constructor].call event[:args][:constructor_args]
    expect(model.processes.size).to eq(2)
    expect(model.processes[:child]).not_to be_nil
    expect(model.processes[:child]).to eq(new_process)
    # serve event of the new process
    event = new_process.serve_system_event :delay_for
    expect(event).to eq({name: :delay_for, args: { time: 400 }})


    # old process again
    # user register_event
    expect {
      e = process.serve_system_event :register_event
      event = e[:args][:event]
      delay = e[:args][:delay]
      args = e[:args][:event_args]
      expect(e[:name]).to eq(:register_event)
      expect(event).to eq(:data)
      expect(delay).to eq(0)
      expect(args).to eq(1000)
      process.enqueue_event(event, args)
      #expect(process.event_queue_size).to eq(4)
    }.not_to change(process, :event_queue_size) # register_event dequeued, new event enqueued


    # send_data
    event = process.serve_system_event :send_data
    expect(event[:name]).to eq(:send_data)
    # CPU time computed for specified CPU
    expect(event[:args]).to eq(to: :child, size: 1024, type: :hello, content: "Hello!")

    # log
    event = process.serve_system_event :log
    expect(event[:name]).to eq(:log)
    expect(event[:args]).to eq("finished main, will serve events")



    # user event :data registered by :register_event, its handler will be run
    # in the future when time comes
    p = process.serve_user_event
    expect(p).to eq(process) # returns modified process

    # Events created by serving the the :data user event above follow:
    event = process.serve_system_event :delay_for
    expect(event).to eq({name: :delay_for, args: { time: 200 }})

    event = process.serve_system_event :cpu
    expect(event[:name]).to eq(:cpu)
    # CPU time computed for specified CPU
    expect(event[:args][:block].call NewProcessSpec::CPU.new).to eq(1)


  end

  describe "#event_time" do
    let :model do
      RBSim.dsl do
        new_process :worker do

          on_event :start do
            start_time = event_time
            register_event :next_one, delay: 100.seconds
          end

          on_event :next_one do
            next_time = event_time
          end

          register_event :start
        end
      end
    end

    it "returns time reported by simulator" do
      simulator = double("simulator")
      expect(simulator).to receive(:clock).twice
      model.simulator = simulator

      e = process.serve_system_event :register_event
      process.enqueue_event e[:args][:event], e[:args][:event_args]

      process.serve_user_event # :start

      process.serve_system_event :register_event
      process.enqueue_event e[:args][:event], e[:args][:event_args]

      process.serve_user_event # :next_one
    end

  end

  describe "#function statement" do
    describe "defines function with access to variable values in correct context" do
      let :model do
        RBSim.dsl do
          new_process :worker do
            @variable = :initial_value

            function :do_something do
              log @variable
            end

            on_event :start do
              do_something
            end

            register_event :start
          end
        end
      end

      it "function reads correct values from variables" do
        e = process.serve_system_event :register_event
        process.enqueue_event e[:args][:event], e[:args][:event_args]

        # :start
        process.serve_user_event

        # value of variable logged by the function
        e = process.serve_system_event :log

        expect(e[:name]).to eq :log
        expect(e[:args]).to eq :initial_value

      end
    end

    describe "defines function with access to correct 'self'" do
      let :model do
        RBSim.dsl do
          new_process :worker do

            function :do_something do
              self
            end

            on_event :start do
              log self
              log do_something
            end

            register_event :start
          end
        end
      end

      it "'self' in function equals to 'self' in calling block" do
        e = process.serve_system_event :register_event
        process.enqueue_event e[:args][:event], e[:args][:event_args]

        # :start
        process.serve_user_event

        # values of variables 'self' 
        # logged by the function...
        log_function = process.serve_system_event :log
        # ...and logged by the action handler block
        log_block = process.serve_system_event :log

        expect(log_function[:args].object_id).to eq log_block[:args].object_id
      end
    end

  end
end

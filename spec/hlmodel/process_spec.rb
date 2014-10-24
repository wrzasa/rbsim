require 'spec_helper'

describe RBSim::HLModel::Process do
  let :block do
      Proc.new do
      end
  end

  subject { RBSim::HLModel::Process.new(:test_node) }

  its(:node){ should eq :test_node }

  # Here is basic usage example
  it "serves user events in order" do
    subject.with_event :be_glad do |who|
      "I am glad #{who}"
    end
    subject.with_event :be_happy do |who|
      "I am happy #{who}"
    end
    subject.register_event :be_happy, "Jack"
    subject.register_event :be_glad, "John"
    subject.register_event :be_happy, "John"
    expect(subject.serve_user_event).to eq "I am happy Jack"
    expect(subject.serve_user_event).to eq "I am glad John"
    expect(subject.serve_user_event).to eq "I am happy John"
  end

  it "serves system events" do
    sysevent1 = subject.system_event_names[0]
    sysevent2 = subject.system_event_names[1]
    subject.register_event sysevent1, block: block, param2: 123
    subject.register_event sysevent2, time: 1000
    expect(subject.serve_system_event).
      to eq({ name: sysevent1, args: { block: block, param2: 123 } })
    expect(subject.serve_system_event).
      to eq({ name: sysevent2, args: { time: 1000 } })
  end

  context "with program name given" do
    subject { RBSim::HLModel::Process.new(:test_node, :apache_webserver) }
    its(:program){ should eq :apache_webserver }
  end

  describe "#with_event" do
    it "registers new event handler" do
      expect {
        subject.with_event :example_event, &block
      }.to change(subject, :handlers_size).by(1)
    end
  end

  describe "#register_event" do
    it "puts user event in event queue" do
      subject.with_event :example_event, &block
      expect {
        subject.register_event :example_event, param1: 123, param2: 345
      }.to change(subject, :event_queue_size).by(1)
    end
    it "puts system event in event queue" do
      system_event = subject.system_event_names.first
      expect {
        subject.register_event system_event
      }.to change(subject, :event_queue_size).by(1)
    end
    it "does not register user event if has no handler" do
      expect {
        subject.register_event :nonexistent_event, params: 23
      }.to raise_error RuntimeError
    end
  end


  describe "#serve_user_event" do
    before :each do
      subject.with_event :example_event, &block
    end
    it "serves first event from queue calling event handler" do
      expect(block).to receive(:call).with(param1: 123, param2: 345)
      subject.register_event :example_event, param1: 123, param2: 345
      subject.serve_user_event
    end
    it "removes served event from queue" do
      subject.register_event :example_event
      expect{ subject.serve_user_event }.to change(subject, :event_queue_size).by(-1)
    end
    it "refuses to serve system event" do
      system_event = subject.system_event_names.first
      subject.register_event system_event
      expect { subject.serve_user_event }.to raise_error RuntimeError
    end
  end

  describe "#serve_system_event" do
    let(:sysevent1){ subject.system_event_names[0] }
    let(:sysevent2){ subject.system_event_names[1] }
    it "serves first event from queue" do
      subject.register_event sysevent1, param1: 123, param2: 345
      expect(subject.serve_system_event).to eq({name: sysevent1, args: { param1: 123, param2: 345 } })
    end
    it "removes served event from queue" do
      subject.register_event sysevent1
      expect{ subject.serve_system_event }.to change(subject, :event_queue_size).by(-1)
    end
    it "refuses to serve user event" do
      subject.with_event :user_event do
      end
      subject.register_event :user_event
      expect { subject.serve_system_event }.to raise_error RuntimeError
    end

  end

  describe "#has_event?" do
    before :each do
      subject.with_event :example_event, &block
    end

    context "without event name" do
      it "is true if user event is first in event queue" do
        subject.register_event :example_event
        expect(subject.has_event?).to be true
      end

      it "is false if event queue is empty" do
        expect(subject.has_event?).to be false
      end

      it "is true if system event is first in queue" do
        system_event = subject.system_event_names.first
        subject.register_event system_event
        expect(subject.has_event?).to be true
      end
    end

    context "with event name" do
      it "is false if event queue is empty" do
        expect(subject.has_event? :example_event).to be false
      end

      it "is true if user event with given name is first in event queue" do
        subject.register_event :example_event
        expect(subject.has_event? :example_event).to be true
      end

      it "is true if system event with given name is first in event queue" do
        system_event = subject.system_event_names.first
        subject.register_event system_event
        expect(subject.has_event? system_event).to be true
      end

      it "is false if user event with given name is not first in event queue" do
        subject.register_event :example_event
        expect(subject.has_event? :other_event).to be false
      end

      it "is false if system event with given name is not first in event queue" do
        system_event = subject.system_event_names[0]
        other_system_event = subject.system_event_names[1]
        subject.register_event system_event
        expect(subject.has_event? other_system_event).to be false
      end
    end
  end

  describe "#has_user_event?" do
    before :each do
      subject.with_event :example_event, &block
    end

    it "is true if user event is first in event queue" do
      subject.register_event :example_event
      expect(subject.has_user_event?).to be true
    end

    it "is false if event queue is empty" do
      expect(subject.has_user_event?).to be false
    end

    it "is false if system event is first in queue" do
      system_event = subject.system_event_names.first
      subject.register_event system_event
      expect(subject.has_user_event?).to be false
    end
  end

  describe "#has_system_event?" do
    before :each do
      subject.with_event :example_event, &block
    end

    it "is false if user event is first in event queue" do
      subject.register_event :example_event
      expect(subject.has_system_event?).to be false
    end

    it "is false if event queue is empty" do
      expect(subject.has_system_event?).to be false
    end

    it "is true if system event is first in queue" do
      system_event = subject.system_event_names.first
      subject.register_event system_event
      expect(subject.has_system_event?).to be true
    end
  end

end

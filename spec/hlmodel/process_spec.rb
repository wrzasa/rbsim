require 'spec_helper'

describe RBSim::HLModel::Process do
  let :block do
      Proc.new do
      end
  end

  describe "#with_event" do
    it "registers new event handler" do
      expect {
        subject.with_event :example_event, &block
      }.to change(subject.event_handlers, :size).by(1)
    end
  end

  describe "#register_event" do
    it "puts user event in event queue" do
      subject.with_event :example_event, &block
      expect {
        subject.register_event :example_event, param1: 123, param2: 345
      }.to change(subject.event_queue, :size).by(1)
    end
    it "puts system event in event queue" do
      system_event = subject.system_event_names.first
      expect {
        subject.register_event system_event
      }.to change(subject.event_queue, :size).by(1)
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
      expect{ subject.serve_user_event }.to change(subject.event_queue, :size).by(-1)
    end
    it "refuses to serve system event" do
      system_event = subject.system_event_names.first
      subject.register_event system_event
      expect { subject.serve_user_event }.not_to change(subject.event_queue, :size)
    end
  end

  describe "#has_event?" do
    before :each do
      subject.with_event :example_event, &block
    end

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
end

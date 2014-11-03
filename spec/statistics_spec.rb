require 'spec_helper'

describe RBSim::Statistics do
  it "correctly computes event frequency" do
    subject.event :stats, :hit, 100
    subject.event :stats, :hit, 300
    subject.event :stats, :hit, 500
    subject.event :stats, :hit, 900
    subject.clock = 1000
    expect(subject.freq[:hit]).to eq(0.004)
  end

  describe "correctly computes event duration" do
    it "for correct data" do
      subject.event :start, :working, 100
      subject.event :stop, :working, 200
      subject.event :start, :working, 300
      subject.event :stop, :working, 400
      subject.event :start, :working, 600
      subject.event :stop, :working, 700
      subject.clock = 1000
      expect(subject.duration[:working]).to eq(0.3)
    end
  end

  # TODO: a warning in this case?
  it "for incorrect data" do
      subject.event :start, :working, 100
      subject.event :start, :working, 150
      subject.event :stop, :working, 200
      subject.event :stop, :working, 250
      subject.event :start, :working, 300
      subject.event :stop, :working, 400
      subject.event :start, :working, 600
      subject.event :stop, :working, 700
      subject.clock = 1000
      expect(subject.duration[:working]).to eq(0.3)
  end

end

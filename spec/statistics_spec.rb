require 'spec_helper'

describe RBSim::Statistics do
  it "has correct event counters" do
    subject.event :stats, { tag: :hit, name: 'db' }, 100
    subject.event :stats, { tag: :hit, name: 'db' }, 300
    subject.event :stats, { tag: :hit, name: 'db' }, 500
    subject.event :stats, { tag: :hit, name: 'db' }, 900
    subject.clock = 1000
    expect(subject.counters['db'][:hit]).to eq(0.004)
  end

  describe "correctly computes event duration" do
    it "for correct data" do
      subject.event :start, { tag: :working, name: 'apache' }, 100
      subject.event :stop, { tag: :working, name: 'apache' }, 200
      subject.event :start, { tag: :working, name: 'apache' }, 300
      subject.event :stop, { tag: :working, name: 'apache' }, 400
      subject.event :start, { tag: :working, name: 'apache' }, 600
      subject.event :stop, { tag: :working, name: 'apache' }, 700
      subject.clock = 1000
      expect(subject.duration['apache'][:working]).to eq(300)
    end
  end

  # TODO: a warning in this case?
  it "for incorrect data" do
      subject.event :start, { tag: :working, name: 'apache' }, 100
      subject.event :start, { tag: :working, name: 'apache' }, 150
      subject.event :stop, { tag: :working, name: 'apache' }, 200
      subject.event :stop, { tag: :working, name: 'apache' }, 250
      subject.event :start, { tag: :working, name: 'apache' }, 300
      subject.event :stop, { tag: :working, name: 'apache' }, 400
      subject.event :start, { tag: :working, name: 'apache' }, 600
      subject.event :stop, { tag: :working, name: 'apache' }, 700
      subject.clock = 1000
      expect(subject.duration['apache'][:working]).to eq(300)
  end

end

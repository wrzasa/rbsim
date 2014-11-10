require 'spec_helper'

describe RBSim::Statistics do
  it "has correct event counters" do
    subject.event :stats, { tag: :hit, group_name: 'db' }, 100
    subject.event :stats, { tag: :hit, group_name: 'db' }, 300
    subject.event :stats, { tag: :hit, group_name: 'db' }, 500
    subject.event :stats, { tag: :hit, group_name: 'db' }, 900
    subject.clock = 1000
    expect(subject.counters['db'][:hit]).to eq(4)
  end

  describe "correctly computes event duration" do
    it "for correct data" do
      subject.event :start, { tag: :working, group_name: 'apache' }, 100
      subject.event :stop, { tag: :working, group_name: 'apache' }, 200
      subject.event :start, { tag: :working, group_name: 'apache' }, 300
      subject.event :stop, { tag: :working, group_name: 'apache' }, 400
      subject.event :start, { tag: :working, group_name: 'apache' }, 600
      subject.event :stop, { tag: :working, group_name: 'apache' }, 700
      subject.clock = 1000
      expect(subject.durations['apache'][:working]).to eq(300)
    end
  end

  # TODO: a warning in this case?
  it "for incorrect data" do
      subject.event :start, { tag: :working, group_name: 'apache' }, 100
      subject.event :start, { tag: :working, group_name: 'apache' }, 150
      subject.event :stop, { tag: :working, group_name: 'apache' }, 200
      subject.event :stop, { tag: :working, group_name: 'apache' }, 250
      subject.event :start, { tag: :working, group_name: 'apache' }, 300
      subject.event :stop, { tag: :working, group_name: 'apache' }, 400
      subject.event :start, { tag: :working, group_name: 'apache' }, 600
      subject.event :stop, { tag: :working, group_name: 'apache' }, 700
      subject.clock = 1000
      expect(subject.durations['apache'][:working]).to eq(300)
  end

end

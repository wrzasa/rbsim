require 'spec_helper'

describe RBSim::Statistics do
  it "has correct event counters" do
    subject.event :stats, { tag: :hit, group_name: 'db' }, 100
    subject.event :stats, { tag: :hit, group_name: 'db' }, 300
    subject.event :stats, { tag: :hit, group_name: 'db' }, 500
    subject.event :stats, { tag: :hit, group_name: 'db' }, 900
    subject.clock = 1000
    expect(subject.counters_summary['db'][:hit]).to eq(4)
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
      expect(subject.durations_summary['apache'][:working]).to eq(300)
    end
  end

  # compute from first :start fo first :stop,
  # from second :start to second :stop and so on...
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
      expect(subject.durations_summary['apache'][:working]).to eq(400)
  end

  it "saves reported values" do
    subject.event :save, { value: 1024, tag: :queue_length, group_name: 'apache' }, 100
    subject.event :save, { value: 1524, tag: :queue_length, group_name: 'apache' }, 100
    subject.event :save, { value: 2048, tag: :queue_length, group_name: 'apache' }, 200
    subject.event :save, { value: 512, tag: :queue_length, group_name: 'apache' }, 400
    expect(subject.values_summary['apache'][:queue_length]).to eq({ 100 => [ 1024, 1524 ], 200 => [ 2048 ], 400 => [ 512 ] })
  end

end

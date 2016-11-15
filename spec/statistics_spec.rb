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
  end

  it "saves reported values" do
    subject.event :save, { value: 1024, tag: :queue_length, group_name: 'apache' }, 100
    subject.event :save, { value: 1524, tag: :queue_length, group_name: 'apache' }, 100
    subject.event :save, { value: 2048, tag: :queue_length, group_name: 'apache' }, 200
    subject.event :save, { value: 512, tag: :queue_length, group_name: 'apache' }, 400
    expect(subject.values_summary['apache'][:queue_length]).to eq({ 100 => [ 1024, 1524 ], 200 => [ 2048 ], 400 => [ 512 ] })
  end

  describe "with hash based tags" do
    describe "event counters" do
      let :stats do
        stats = RBSim::Statistics.new
        stats.event :stats, { score: :hit, target: 'small' }, 100
        stats.event :stats, { score: :hit, target: 'big' }, 300
        stats.event :stats, { score: :miss, target: 'small' }, 500
        stats.event :stats, { score: :hit, target: 'small' }, 500
        stats.event :stats, { score: :miss, target: 'small' }, 500
        stats.event :stats, { score: :hit, target: 'big' }, 900
        stats.event :stats, { score: :hit3, target: 'big' }, 900
        stats.event :stats, { score: :hit, target: 'big', value: 23 }, 900
        stats.event :stats, { score: :hit, target: 'big', value: 230 }, 900
        stats.event :stats, { score: :hit5, target: 'huge' }, 950
        stats.clock = 1000
        stats
      end
      subject { stats }

      it "returns all counters" do
        counters = subject.counters
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
          { score: :miss, target: 'small' } => [ 500, 500 ],
          { score: :hit3, target: 'big' } => [ 900 ],
          { score: :hit5, target: 'hudge' } => [ 950 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by single tag" do
        counters = subject.counters(score: :hit)
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by two tags" do
        counters = subject.counters(score: :hit, target: 'big')
        expected_counters = {
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by rare tag" do
        counters = subject.counters(value: 23)
        expected_counters = {
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by regexp" do
        counters = subject.counters(score: /hit./)
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
          { score: :hit3, target: 'big' } => [ 900 ],
          { score: :hit5, target: 'hudge' } => [ 950 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by empty regexp" do
        counters = subject.counters(value: //)
        expected_counters = {
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

    end

    describe "correctly computes event duration" do
      context "for correct data" do
        it "returns all durations"
        it "filters durations by single tag"
        it "filters durations by two tags"
        it "filters durations by rare tag"
        it "filters durations by regexp"
        it "filters durations by empty regexp"
      end
      context "for incorrect data" do
        it "correctly yields first start with first stop and so on"
      end
    end

    describe "saves reported values" do
      it "returns all values"
      it "filters values by single tag"
      it "filters values by two tags"
      it "filters values by rare tag"
      it "filters values by regexp"
      it "filters values by empty regexp"
    end
  end

end

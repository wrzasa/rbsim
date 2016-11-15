require 'spec_helper'

describe RBSim::Statistics do

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
        counters = subject.counters.to_h
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
          { score: :miss, target: 'small' } => [ 500, 500 ],
          { score: :hit3, target: 'big' } => [ 900 ],
          { score: :hit5, target: 'huge' } => [ 950 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by single tag" do
        counters = subject.counters(score: :hit).to_h
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by two tags" do
        counters = subject.counters(score: :hit, target: 'big').to_h
        expected_counters = {
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by rare tag" do
        counters = subject.counters(value: 23).to_h
        expected_counters = {
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by regexp" do
        counters = subject.counters(score: /hit.?/).to_h
        expected_counters = {
          { score: :hit, target: 'small' } => [ 100, 500 ],
          { score: :hit, target: 'big' } => [ 300, 900 ],
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
          { score: :hit3, target: 'big' } => [ 900 ],
          { score: :hit5, target: 'huge' } => [ 950 ],
        }
        expect(counters).to eq expected_counters
      end

      it "filters counters by any regexp matching any value if key exists" do
        counters = subject.counters(value: /.*/).to_h
        expected_counters = {
          { score: :hit, target: 'big', value: 23 } => [ 900 ],
          { score: :hit, target: 'big', value: 230 } => [ 900 ],
        }
        expect(counters).to eq expected_counters
      end

    end

    describe "correctly computes event duration" do
      context "for correct data" do
        let :stats do
          stats = RBSim::Statistics.new
          stats.event :start, { tag: :working, name: 'apache' }, 100
          stats.event :start, { tag: :working, name: 'nginx'  }, 100

          stats.event :start, { tag: :request, name: 'apache' }, 200
          stats.event :stop,  { tag: :request, name: 'apache' }, 300
          stats.event :start, { tag: :request, name: 'nginx'  }, 350
          stats.event :start, { tag: :request, name: 'apache' }, 350
          stats.event :stop,  { tag: :request, name: 'nginx'  }, 400
          stats.event :stop,  { tag: :request, name: 'apache' }, 420
          stats.event :start, { tag: :compute, name: 'apache', mod: :php }, 500
          stats.event :stop,  { tag: :compute, name: 'apache', mod: :php }, 600

          stats.event :stop,  { tag: :working, name: 'nginx'  }, 850
          stats.event :stop,  { tag: :working, name: 'apache' }, 900
          stats.clock = 1000

          stats
        end

        subject { stats }

        it "returns all durations" do
          durations = subject.durations.to_a
          expected_durations = [
            [ { tag: :working, name: 'apache' }, 100, 900 ],
            [ { tag: :working, name: 'nginx'  }, 100, 850 ],
            [ { tag: :request, name: 'apache' }, 200, 300 ],
            [ { tag: :request, name: 'apache' }, 350, 420 ],
            [ { tag: :compute, name: 'apache', mod: :php }, 500, 600 ],
            [ { tag: :request, name: 'nginx'  }, 350, 400 ],
          ]
          expect(durations).to match_array expected_durations
        end

        it "filters durations by single tag" do
          durations = subject.durations(tag: :working).to_a
          expected_durations = [
            [ { tag: :working, name: 'apache' }, 100, 900 ],
            [ { tag: :working, name: 'nginx'  }, 100, 850 ],
          ]
          expect(durations).to match_array expected_durations
        end

        it "filters durations by two tags" do
          durations = subject.durations(tag: :request, name: 'apache').to_a
          expected_durations = [
            [ { tag: :request, name: 'apache' }, 200, 300 ],
            [ { tag: :request, name: 'apache' }, 350, 420 ],
          ]
          expect(durations).to match_array expected_durations
        end

        it "filters durations by rare tag" do
          durations = subject.durations(tag: :compute).to_a
          expected_durations = [
            [ { tag: :compute, name: 'apache', mod: :php }, 500, 600 ],
          ]
          expect(durations).to match_array expected_durations
        end

        it "filters durations by regexp" do
          durations = subject.durations(tag: /r/).to_a
          expected_durations = [
            [ { tag: :working, name: 'apache' }, 100, 900 ],
            [ { tag: :working, name: 'nginx'  }, 100, 850 ],
            [ { tag: :request, name: 'apache' }, 200, 300 ],
            [ { tag: :request, name: 'apache' }, 350, 420 ],
            [ { tag: :request, name: 'nginx'  }, 350, 400 ],
          ]
          expect(durations).to match_array expected_durations
        end

        it "filters durations by any regexp matching any value if key exists" do
          durations = subject.durations(mod: /.*/).to_a
          expected_durations = [
            [ { tag: :compute, name: 'apache', mod: :php }, 500, 600 ],
          ]
          expect(durations).to match_array expected_durations
        end

      end
      context "for incorrect data" do
        let :stats do
          stats = RBSim::Statistics.new
          stats.event :start, { tag: :request, name: 'apache' }, 200
          stats.event :start, { tag: :request, name: 'apache' }, 300
          stats.event :start, { tag: :request, name: 'apache' }, 400
          stats.event :stop,  { tag: :request, name: 'apache' }, 450
          stats.event :stop,  { tag: :request, name: 'apache' }, 550
          stats.event :stop,  { tag: :request, name: 'apache' }, 650

          stats.clock = 1000

          stats
        end

        subject { stats }

        it "correctly yields first start with first stop and so on" do
          durations = subject.durations.to_a
          expected_durations = [
            [ { tag: :request, name: 'apache' }, 200, 450 ],
            [ { tag: :request, name: 'apache' }, 300, 550 ],
            [ { tag: :request, name: 'apache' }, 400, 650 ],
          ]
          expect(durations).to match_array expected_durations
        end
      end
    end

    describe "saves reported values" do
      let :stats do
        stats = RBSim::Statistics.new

        stats.event :save, { value: 1024, tags: { tag: :queue_length, name: 'apache' } }, 100
        stats.event :save, { value: 1524, tags: { tag: :queue_length, name: 'apache' } }, 100
        stats.event :save, { value: 1024, tags: { tag: :queue_length, name: 'nginx'  } }, 100
        stats.event :save, { value: 2048, tags: { tag: :queue_length, name: 'apache' } }, 200
        stats.event :save, { value: 2048, tags: { tag: :queue_length, name: 'apache', mod: :php } }, 200
        stats.event :save, { value: 2048, tags: { tag: :queue_length, name: 'nginx'  } }, 200
        stats.event :save, { value: 2048, tags: { tag: :queue_length, name: 'nginx', mod: :php  } }, 300
        stats.event :save, { value: 20,   tags: { tag: :wait_time, name: 'nginx'     } }, 350
        stats.event :save, { value: 512,  tags: { tag: :queue_length, name: 'apache' } }, 400
        stats.event :save, { value: 30,   tags: { tag: :wait_time, name: 'nginx'     } }, 400

        stats.clock = 1000

        stats
      end

      subject { stats }

      it "returns all values" do
        values = subject.values.to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache' }, 100, [ 1024, 1524 ] ],
          [ { tag: :queue_length, name: 'nginx'  }, 100, [ 1024 ] ],
          [ { tag: :queue_length, name: 'apache' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx', mod: :php }, 300, [ 2048 ] ],
          [ { tag: :wait_time, name: 'nginx' }, 350, [ 20 ] ],
          [ { tag: :queue_length, name: 'apache' }, 400, [ 512 ] ],
          [ { tag: :wait_time, name: 'nginx' }, 400, [ 30 ] ],
        ]
        expect(values).to match_array expected_values
      end

      it "filters values by single tag" do
        values = subject.values(tag: :queue_length).to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache' }, 100, [ 1024, 1524 ] ],
          [ { tag: :queue_length, name: 'nginx'  }, 100, [ 1024 ] ],
          [ { tag: :queue_length, name: 'apache' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx', mod: :php }, 300, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache' }, 400, [ 512 ] ],
        ]
        expect(values).to match_array expected_values
      end

      it "filters values by two tags" do
        values = subject.values(tag: :queue_length, name: 'apache').to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache' }, 100, [ 1024, 1524 ] ],
          [ { tag: :queue_length, name: 'apache' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache' }, 400, [ 512 ] ],
        ]
        expect(values).to match_array expected_values
      end

      it "filters values by rare tag" do
        values = subject.values(mod: :php).to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx', mod: :php }, 300, [ 2048 ] ],
        ]
        expect(values).to match_array expected_values
      end

      it "filters values by regexp" do
        values = subject.values(name: /^a.*/).to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache' }, 100, [ 1024, 1524 ] ],
          [ { tag: :queue_length, name: 'apache' }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'apache' }, 400, [ 512 ] ],
        ]
        expect(values).to match_array expected_values
      end

      it "filters values by any regexp matching any value if key exists" do
        values = subject.values(mod: /.*/).to_a
        expected_values = [
          [ { tag: :queue_length, name: 'apache', mod: :php }, 200, [ 2048 ] ],
          [ { tag: :queue_length, name: 'nginx', mod: :php }, 300, [ 2048 ] ],
        ]
        expect(values).to match_array expected_values
      end

    end
  end

end

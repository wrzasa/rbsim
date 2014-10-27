page 'application' do
  process = place 'process'
  cpu = place 'CPU'

  transition 'event::delay_for' do
    input process, :process
    output process do |binding, clock|
      process = binding[:process][:val]
      event = process.serve_system_event :delay_for
      ts = clock + event[:args][:time]
      { val: process, ts: ts }
    end

    guard do |binding, clock|
      binding[:process][:val].has_event? :delay_for
    end
  end

  transition 'event::cpu' do
    input process, :process
    input cpu, :cpu

    def processing_delay(binding)
      process = binding[:process][:val]
      cpu = binding[:cpu][:val]
      event = process.serve_system_event :cpu
      event[:args][:block].call cpu
    end

    output process do |binding, clock|
      { val: process, ts: clock + processing_delay(binding) }
    end

    output cpu do |binding, clock|
      { val: cpu, ts: clock + processing_delay(binding) }
    end

    guard do |binding, clock|
      if binding[:process][:val].has_event?(:cpu) &&
         (binding[:process][:val].node == binding[:cpu][:val].node)
        true
      else
        false
      end
    end
  end
end

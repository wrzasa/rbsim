page 'application' do
  process = place 'process'
#  cpu = place 'CPU'

  transition 'delay_for' do
    input process, :process
    output process do |binding, clock|
      process = binding[:process][:val]
      event = process.serve_system_event :delay_for
      time = clock + event[:args][:time]
      { val: process, ts: clock + time }
    end

    guard do |binding, clock|
      binding[:process][:val].has_event? :delay_for
    end
  end
end

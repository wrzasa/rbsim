require 'rbsim'

# new_process statement example usage
# use this to create specs!
# This will be a kind of integration specs for dsl and hlmodel:
# Test behavior of hlmodel defined by the DSL statements

model = RBSim.dsl do
  new_process :worker do
    with_event :data do |volume|
      delay_for 100
      cpu do |c|
        12/c.performance
      end
    end
    delay_for 100
    cpu do |cpu|
      100/cpu.performance
    end
    register_event :data, 1000
  end
end

puts "Model: "
p model

puts "="*60
puts "Serving process events"
p = model.processes[:worker]
p.node = :node01

puts "-"*60
e = p.serve_system_event :delay_for
puts "delay_for: #{e.inspect}"


puts "-"*60
cpu = Object.new
def cpu.performance
  20
end
e = p.serve_system_event :cpu
puts "cpu: #{e.inspect} computed CPU delay: #{e[:args][:block].call cpu}"

puts "-"*60
puts "Process after serving user event :data (note event_queue modified by this event)"
p.serve_user_event # returns process object (self)!
puts p.inspect


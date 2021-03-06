require 'rbsim'

client_no = 1
router_no = 100
server_no = 10
request_per_client = 1000
request_gap = 30.miliseconds
long_prob = 0.01
REQUEST_TIMES = {
  long: 5000.miliseconds,
  short: 50.miliseconds
}

model = RBSim.model do

  # gets array of server names and assigns
  # requests to servers using round-robin, but
  # next request is assigned to a server only
  # when previous is served.
  program :router do |servers|
    request_queue = []
    on_event :data_received do |data|
      if data.type == :request
        stats :requests, process.name
        request_queue << data
        stats_start :request_in_queue, process.name
        register_event :process_request
        stats_save request_queue.size, :rqueue_len, process.name
      elsif data.type == :response
        servers << data.src
        send_data to: data.content[:from], size: data.size, type: :response, content: data.content[:content]
        register_event :process_request
      else
        raise "Unknown data type #{data.type} received by #{process.name}"
      end
    end

    on_event :process_request do
      unless servers.empty? or request_queue.empty?
        data = request_queue.shift
        stats_stop :request_in_queue, process.name
        server = servers.shift
        stats_save request_queue.size, :rqueue_len, process.name
        send_data to: server, size: data.size, type: :request, content: { from: data.src, content: data.content }
        register_event :process_request unless request_queue.empty?
      end
    end
  end

  program :webserver do
    on_event :data_received do |data|
      if data.type == :request
        tag = "request_#{data.content[:content][:length]}".to_sym
        stats tag, process.name
        stats :request, process.name
        #log "#{process.name} got request #{data.content[:content][:number]} from #{data.content[:from]} #{data.content[:content][:length]}"
        cpu do |cpu|
          # request holds information about its processing time
          REQUEST_TIMES[data.content[:content][:length]] / cpu.performance
        end
        data.content[:content].merge!({ server: process.name })
        send_data to: data.src, size: data.size * 10, type: :response, content: data.content
      else
        raise "Unknown data type #{data.type} received by #{process.name}"
      end
    end
  end

  # opts are: count, delay, target
  program :wget do |opts|
    sent = 0
    on_event :send do
      length = if rand < opts[:long_prob]
                  stats :requests_long#, process.name
                  stats_start :requests_long#, process.name
                  :long
                else
                  stats :requests_short#, process.name
                  stats_start :requests_short#, process.name
                  :short
                end
      content = { number: sent, length: length }
      target = opts[:targets][rand opts[:targets].length]
      send_data to: target, size: 1024.bytes, type: :request, content: content
      #log "#{process.name} sent request #{sent} #{length}"
      stats_start :request, process.name
      stats_start "request_#{sent}".to_sym, process.name
      sent += 1
      register_event :send, delay: opts[:delay] if sent < opts[:count]
    end

    on_event :data_received do |data|
      stats_stop :request, process.name
      stats_stop "requests_#{data.content[:length]}".to_sym#, process.name
      #log "#{process.name} got response #{data.content[:number]} #{data.content[:server]} #{data.content[:length]}"
      stats :request_served, process.name
      stats_stop "request_#{data.content[:number]}".to_sym, process.name
    end

    register_event :send
  end





  clients = (0..client_no - 1).map { |i| "client#{i}".to_sym }
  routers = (0..router_no - 1).map { |i| "router#{i}".to_sym }
  servers = (0..server_no - 1).map { |i| "thin#{i}".to_sym }

  servers.each do |s|
    node s do
      cpu 1
    end
    new_process s, program: :webserver
    put s, on: s
  end


  routers.each_with_index do |r, i|
    new_process r, program: :router, args: servers.clone
    node r do
      cpu 1
    end
    put r, on: r
  end

  clients.each do |c|
    new_process c, program: :wget, args: { count: request_per_client, delay: request_gap, targets: routers, long_prob: long_prob }
    node c do
      cpu 1
    end
    put c, on: c

    routers.each do |r|
      route from: c, to: r, via: [ :wan ], twoway: true
    end
  end

  net :wan, bw: 102400.bps
  net :lan, bw: 1024000.bps


  servers.each do |s|
    routers.each do |r|
      route from: r, to: s, via: [ :lan ], twoway: true
    end
  end

end

prev_seconds = 0
model.tcpn.cb_for :clock, :after do |tag, event|
  print "\b"*40
  seconds = event.clock.in_seconds.truncate
  print "Time: #{seconds} sec." if seconds > prev_seconds
  prev_seconds = seconds
end

puts "Clients\t\t: #{client_no}"
puts "Routers\t\t: #{router_no}"
puts "Servers\t\t: #{server_no}"
puts "Requests\t: #{request_per_client}"
puts "Request gap\t: #{request_gap.in_miliseconds}ms"
puts "Long req. prob.\t: #{long_prob}"
puts "Request times\t: #{REQUEST_TIMES.map{ |n,t| "#{n}: #{t.in_miliseconds}ms"}.join ', '}"
puts

model.run

#model.stats_print
#p model.stats_summary

=begin
puts "======================="
puts "Routers' queue length"
model.stats_data[:application].values.each do |process, tag, time, values|
  next unless tag == :rqueue_len
  puts "#{process}\t#{time}: #{values.last}"
end
=end
puts

max_rqueue_len = model.stats_summary[:application][:values].map do |process, records|
  records[:rqueue_len].map{ |time, values| values.last }.max
end.max

max_thinqueue_len = model.stats_summary[:resources][:values]['DATAQ LEN'].map do |process, records|
  if process.to_s =~ /thin*/
    records.map{ |time, values| values.last }.max
  else
    0
  end
end.max

#max_thinqueue_wait = model.stats_summary[:resources][:durations]['DATAQ WAIT'].select do |process, time|
#  process.to_s =~ /thin*/
#end.values.max

max_thinq_wait = nil
model.stats_data[:resources].durations do |group, tag, start, stop|
  next unless group == 'DATAQ WAIT'
  next unless tag.to_s =~ /thin.*/
  if max_thinq_wait.nil? || (stop - start) > max_thinq_wait[:time]
    max_thinq_wait = { time: stop - start, tag: tag }
  end
end

sum_rqueue_wait = 0
max_rqueue_wait = 0
model.stats_data[:application].durations do |group, tag, start, stop|
  next unless group.to_s =~ /router.*/
  next unless tag == :request_in_queue
  wait = stop - start
  sum_rqueue_wait += wait
  max_rqueue_wait = wait if wait > max_rqueue_wait
end

summary_thinqueue_wait = model.stats_summary[:resources][:durations]['DATAQ WAIT'].select do |process, time|
  process.to_s =~ /thin*/
end.values.reduce(:+)

puts
puts "Max rtr queue len\t: #{max_rqueue_len}"
puts "Max rtr queue wait\t: #{max_rqueue_wait.in_miliseconds}ms"
puts "Sum rtr queue wait\t: #{sum_rqueue_wait.in_miliseconds}ms"
puts "Avg rtr queue wait\t: #{(sum_rqueue_wait/(client_no*request_per_client)).in_miliseconds}ms"
puts "Max thin queue len\t: #{max_thinqueue_len}"
puts "Max thin queue wait\t: #{max_thinq_wait[:time].in_miliseconds}ms #{max_thinq_wait[:tag]}"
puts "Sum thin queue wait\t: #{summary_thinqueue_wait.in_miliseconds}ms"
puts "Avg. thin queue wait\t: #{(summary_thinqueue_wait/(client_no*request_per_client)).in_miliseconds}ms"

long_time = (model.stats_summary[:application][:durations][""][:requests_long] || 0).to_f
short_time = (model.stats_summary[:application][:durations][""][:requests_short] || 0).to_f
long_count = (model.stats_summary[:application][:counters][""][:requests_long] || 0).to_f
short_count = (model.stats_summary[:application][:counters][""][:requests_short] || 0).to_f

if short_count > 0
  short_req_avg = short_time / short_count
  puts "Short req. avg\t\t: #{short_req_avg.in_miliseconds}ms"
end

if long_count > 0
  long_req_avg = long_time / long_count
  puts "Long req. avg\t\t: #{long_req_avg.in_miliseconds}ms"
end

file = "rtr_#{router_no}_req_#{request_per_client}.dump"
model.stats_save file
puts "\nStats saved in #{file}"


require 'rbsim'

client_no = 10
router_no = 1
server_no = 10
request_per_client = 1
request_gap = 600.miliseconds
long_prob = 0.1
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
        log "#{process.name} got request #{data.content[:content][:number]} from #{data.content[:from]} #{data.content[:content][:length]}"
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
      log "#{process.name} sent request #{sent} #{length}"
      stats_start :request, process.name
      stats_start "request_#{sent}".to_sym, process.name
      sent += 1
      register_event :send, delay: opts[:delay] if sent < opts[:count]
    end

    on_event :data_received do |data|
      stats_stop :request, process.name
      stats_stop "requests_#{data.content[:length]}".to_sym#, process.name
      log "#{process.name} got response #{data.content[:number]} #{data.content[:server]} #{data.content[:length]}"
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

model.run

model.stats_print
p model.stats_summary

puts "======================="
puts "Routers' queue length"
model.stats_summary[:application][:values].each do |process, records|
  puts process
  puts records[:rqueue_len].map{ |time, values| "\t#{time}: #{values.last}" }.join "\n"
end
puts

max_rqueue_len = model.stats_summary[:application][:values].map do |process, records|
  records[:rqueue_len].map{ |time, values| values.last }.max
end.max

puts "Clients\t\t: #{client_no}"
puts "Routers\t\t: #{router_no}"
puts "Servers\t\t: #{server_no}"
puts "Requests\t: #{request_per_client}"
puts "Request gap\t: #{request_gap.in_miliseconds}ms"
puts "Long req. prob.\t: #{long_prob}"
puts "Max rqueue len\t: #{max_rqueue_len}"
puts "Request times\t: #{REQUEST_TIMES.map{ |n,t| "#{n}: #{t.in_miliseconds}ms"}.join ', '}"
puts

long_time = (model.stats_summary[:application][:durations][""][:requests_long] || 0).to_f
short_time = (model.stats_summary[:application][:durations][""][:requests_short] || 0).to_f
long_count = (model.stats_summary[:application][:counters][""][:requests_long] || 0).to_f
short_count = (model.stats_summary[:application][:counters][""][:requests_short] || 0).to_f

if short_count > 0
  short_req_avg = short_time / short_count
  puts "Short req. avg\t: #{short_req_avg.in_miliseconds}ms"
end

if long_count > 0
  long_req_avg = long_time / long_count
  puts "Long req. avg\t: #{long_req_avg.in_miliseconds}ms"
end

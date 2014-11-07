require 'rbsim'

model = RBSim.model do

  # gets array of server names and assigns
  # requests to servers using round-robin, but
  # next request is assigned to a server only
  # when previous is served.
  program :router do |servers|
    request_queue = []
    on_event :data_received do |data|
      if data.type == :request
        request_queue << data
        register_event :process_request
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
        send_data to: server, size: data.size, type: :request, content: { from: data.src, content: data.content }
        register_event :process_request unless request_queue.empty?
      end
    end
  end

  program :webserver do
    on_event :data_received do |data|
      if data.type == :request
        tag = "request_#{data.content[:content][:length].in_miliseconds}".to_sym
        stats tag, process.name
        stats :request, process.name
        log "#{process.name} got request #{data.content[:content][:length].in_miliseconds}"
        cpu do |cpu|
          # request holds information about its processing time
          data.content[:content][:length] / cpu.performance
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
                  stats :requests_long, process.name
                  stats_start :requests_long, process.name
                  5000.miliseconds
                else
                  stats :requests_short, process.name
                  stats_start :requests_short, process.name
                  50.miliseconds
                end
      content = { number: sent, length: length }
      send_data to: opts[:target], size: 1024.bytes, type: :request, content: content
      log "#{process.name} sent data #{sent} #{length.in_miliseconds}"
      stats_start :request, process.name
      sent += 1
      delay_for opts[:delay]
      register_event :send if sent < opts[:count]
    end

    on_event :data_received do |data|
      stats_stop :request, process.name
      if data.content[:length] == 50.miliseconds
        stats_stop :requests_short, process.name
      else
        stats_stop :requests_long, process.name
      end
      log "#{process.name} got data #{data.content[:number]} #{data.content[:server]} #{data.content[:length].in_miliseconds}"
      stats :request_served, process.name
    end

    register_event :send
  end





  servers = (0..10).map { |i| "thin#{i}".to_sym }
  routers = (0..10).map { |i| "router#{i}".to_sym }
  requests = 100
  long_prob = 0.1

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

    c = "client#{i}".to_sym
    new_process c, program: :wget, args: { count: requests, delay: 600.miliseconds, target: r, long_prob: long_prob }
    node c do
      cpu 1
    end
    put c, on: c

    route from: c, to: r, via: [ :wan ], twoway: true
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

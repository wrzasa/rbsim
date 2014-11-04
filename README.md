RBSim
=====

RBSim is a simulation tools designed for analysis of concurrent
and distributed applications. Application should be descibed
using convenient Ruby-based DSL. Simulation is based on Timed
Colored Petri nets designed by K. Jensen, thus ensuring reliable
analysis. Basic statistics module is included.

## Usage

1. Define your model using `RBSim.model` method.
    model = RBSim.model do

      # define your model here

    end
1. Run simulator:
    model.run
1. Collect statistics:
    model.stats_print

To collect statistics you can also use
* `model.stats_summary` to get Hash of summary
* `model.stats_data` to get Hash with objects holding complete
  data collected from simulation

## Model

Use `RBSim.model` to load model described by DSL. The model is a
set of `process`es that are `put` on `nodes` and communicate over
`net`s. Processes can be defined by `programs` or directly by
blocks, `route`s define sequence of `net`s that should be
traversed by data while communication between `node`s.
Application logic implemented in `process`es is described in
terms of events.

### Processes

Processes are defined by `new_process` statement.

        new_process :sender1 do
          delay_for time: 100
          cpu do |cpu|
            10000/cpu.performance
          end
        end

#### Delay and CPU Load

First parameter of the statement is the process name which must
be unique in the whole model.

A process can no nothing for some time -- `delay_for.

It can alos load node's CPU for specified time. This is defined
by `cpu` statement. Load time is defined by results of block
passed to the statement. The parameter passed to the block
represents CPU to which this work is assigner. Performance of
this CPU can be checked using `cpu.performance`.

Time values defined by `delay_for` and returned by the `cpu` block
can be random.

#### Events and Handlers

Defining process one can use `on_event` statement, to define
process behavior for an event. Process can also register events
using `register_event` statement. This is recommended method of
describing processes behavior, also recurring behaviors. The
following example will repeat sending data 10 times.

  new_process :wget do
    sent = 0
    on_event :send do
      cpu do |cpu|
        150/cpu.performance
      end
      sent += 1
      delay_for 5
      register_event :send if sent < 10
    end

    register_event :send
  end


#### Communication

##### Sending data

A process can send data to another process using its name as
destination address.

      new_process :sender1 do
        send_data to: :receiver, size: 1024, type: :request, content: 'anything useful for your model'
      end

Data will be sent to process called `:receiver`, size will be
1024. `type` and `content` of the data can be set to anything useful.

##### Receiving data

Every process is capable of receiving data, but by default the
data will be dropped and a warning issued. To process received
data, process must define event handler for `:data_received`
event.

        on_event :data_received do |data|
          cpu do |cpu|
            data.size / cpu.performance
          end
        end

The parameter passed to the event handler (`data` in the example
above) contains a Hash describing received data.

  { src: :source_process_name,
    dst: :destination_process_name,
    size: data_size,
    type: 'a value_given_by_sender',
    content: 'a value given by sender' }

The complete example of wget -- sending requests and receiving
responses can look like this:

  new_process :wget do
    sent = 0
    on_event :send do
      cpu do |cpu|
        150/cpu.performance
      end
      send_data to: opts[:target], size: 1024, type: :request, content: sent
      sent += 1
      delay_for 5
      register_event :send if sent < 10
    end

    on_event :data_received do |data|
      log "Got data #{data} in process #{process.name}"
      stats :request_served, process.name
    end

    register_event :send
  end

##### Logs and statistics

The `log` statement can be used in the process description, to
send a message to logs (by default to STDOUT).

The `stats` statements can be used to collect running statistics.

* `stats_start tag [, group_name]` marks start of an activity
* `stats_stop tag [, group_name]` marks start of an activity
* `stats tag [, group_name]` marks that a counter marked by `tag`
  should be increased

The optional `group_name` parameter allows one to group
statistics by additional name, e.g. name of specific process
(apache1, apache2, apache2, ...) in which they were collected.

##### Variabeles, Conditions, Loops

As shown in examples above, variables can be used to steer
behavior of a process. Their visibility should be intuitive.
Don't use Ruby's instance variables -- `@something` -- didn't
test it, but no guarantee given!

You can also get name of current process from `process.name`.

Using conditional statements is encouraged wherever it is useful.
Using loops is definitely NOT encouraged. It can (and most probably
will) create long event queues which will slow down simulation.
You should rather use recurring events, as in the example with
wget model.

### Programs

Programs can be used to define the same logic used in a numebr of
processes. Their names can be the used to define processes


        program :waiter do |time|
          delay_for time: time
        end

        program :worker do |volume|
          cpu do |cpu|
            volume * volume / cpu.performance
          end
        end

These two programs can be used to define processes:

    new_process program: waiter, args: 100
    new_process program: worker, args: 2000

`args` passed to the `new_process` statement will be passed to
the block defining program. So in the example above `time`
parameter of `:waiter` process will be set to 100 and `volume`
parameter of the `:worker` process will be set to 2000.

### Resources

Resources are described in terms of `node`s equipped with `cpu`s
of given performance and `net`s with given `name` bandwidth
(`bw`). Routes between `node`s are defined using `route`
statement.

#### Nodes

Nodes are defined using `node` statement, cpus inside nodes using
`cpu` statement with performance as parameter.

    node :laptop do
      cpu 1000
      cpu 1000
      cpu 1000
    end

The performance defined here, can be used in `cpu` statement in
process description.


#### Nets

Nets used in communication are defined with `net` statement with
name as parameter and a Hash definind other parameters of the
segment, currently only bandwidth.

    net :lan, bw: 1024
    net :subnet1, bw: 20480

#### Routes

Routes are used to define which `net` segments should be traversed
by data transmitted between two given `node`s. Routes can be
one-way (default) or two-way.

        route from: :laptop, to: :node02, via: [ :net01, :net02 ]
        route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: true
        route from: :node06, to: :node07, via: [ :net07, :net01 ], twoway: :true

Communication between processes located on different nodes
requires a route defined between the nodes. If there is more then
one route between nodes, random one is selected.  A node can
communicate with itself without any route defined and without
travesrsing any `net` segemtns

### Mapping of Application to Resources

When application is defined as a set of processes and resources
are defined as nodes connected with net segments, the application
can be mapped to the nodes. Mapping is defined using `put`
statement.

    put :wget, on: :laptop
    put :server1, on: :gandalf

First parameter is process name, second (after `on:`) is node
name.

Thus application logic and topology does not depent in any way on
topology of resources. The sam application can be mapped to
different resources in different way. The same resource set can
be used for different applications.

### Example

Below is a simble but complete example model of wto applications:
`wget` sending subsequent requests to specified process and
`apache` responding to received requests. 

The `wget` program accepts parameters describing its target
(destination of requests) -- `opts[:target]` and count of
requests to send `opts[:count]`. The paremeters are defined when
new process is defined using this program.  The `apache` program
takes no additional parameters.

Two client processes are started using program `wget`: `client1`
and `client2`. Using `apache` program one server is started:
`server`. Application uses two nodes: `desktop` with one slower
processor and `gandalf` with one faterr CPU. The nodes are
connected by two nets and ne two-way route.  Both clients are
assigned to the `desktop` node while server is run on `gandalf`.

Logs are print to STDOUT and statistics are collected. Apache
`stats` definitions allow to observe time taken by serving
requests. Client `stats` count served requests and allow to
verify if aresponses were received for all sent requests.


The clients are mapped to 

    require 'rbsim'

    model = RBSim.model do

      program :wget do |opts|
        sent = 0
        on_event :send do
          cpu do |cpu|
            150/cpu.performance
          end
          send_data to: opts[:target], size: 1024, type: :request, content: sent
          sent += 1
          delay_for 5
          register_event :send if sent < opts[:count]
        end

        on_event :data_received do |data|
          log "Got data #{data} in process #{process.name}"
          stats :request_served, process.name
        end

        register_event :send
      end

      program :apache do
        on_event :data_received do |data|
          stats_start :apache, process.name
          cpu do |cpu|
            100*data.size / cpu.performance
          end
          send_data to: data.src, size: data.size * 10, type: :response, content: data.content
          stats_stop :apache, process.name
        end
      end

      node :desktop do
        cpu 100
      end

      node :gandalf do
        cpu 1400
      end

      new_process :client1, program: :wget, args: { target: :server, count: 10 }
      new_process :client2, program: :wget, args: { target: :server, count: 10 }
      new_process :server, program: :apache

      net :net01, bw: 1024
      net :net02, bw: 510

      route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true

      put :server, on: :gandalf
      put :client1, on: :desktop
      put :client2, on: :desktop

    end

## Custom Logger 

TODO

## Custom Statistics Collector

TODO

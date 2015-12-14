RBSim
=====

RBSim is a simulation tools designed for analysis of architecture of
concurrent and distributed applications. Application should be descibed
using convenient Ruby-based DSL. Simulation is based on Timed Colored
Petri nets designed by K. Jensen, thus ensuring reliable analysis. Basic
statistics module is included.

## Usage

Define your model using `RBSim.model` method:

    model = RBSim.model some_params do |params|
      # define your model here
      # use params passed to the block
    end

Or read the model from a file:

    model = RBSim.read file_name, some_params_hash

+some_params_hash+ will be available in the model loaded from the file
as +params+ variable.


Run simulator:

    model.run

Collect statistics:

    model.stats_print

To collect statistics you can also use

 - `model.stats_summary` to get Hash of summary
 - `model.stats_data` to get Hash with objects holding complete
   data collected from simulation

## Model

Use `RBSim.model` to create model described by DSL in a block or
`RBSim.read` to load a model from separate file.

The model is a set of `process`es that are `put` on `nodes` and
communicate over `net`s. Processes can be defined by `program`s or
directly by blocks, `route`s define sequence of `net`s that should be
traversed by data while communication between `node`s.  Application
logic implemented in `process`es is described in terms of events.

So to summarize, the most important parts of the model are:

 - Application described as a set of `processes`
 - Resources described as
   - `nodes` (computers)
   - `nets` (network segemtns)
   - `routes` (from one node to another, over the `net` segments
 - Mapping of application `processes` to `nodes`

The application can be modeled independently, resources can be
modeled separately and at the end, the application can be mapped
to the resources.

### Processes

Processes are defined by `new_process` statement.

    new_process :sender1 do
      delay_for time: 100
      cpu do |cpu|
        (10000 / cpu.performance).miliseconds
      end
    end

First parameter of the statement is the process name which must
be unique in the whole model. The block defines behavior of the process
using statements described below.

#### Delay and CPU Load

A process can do nothing for some time. This is specified with
`delay_for` statement.

    delay_for 100.seconds
or

    delay_for time: 100.seconds

Using `delay_for` causes process to stop for specified time. It
will not occupy resources, but it will not serve any incoming
event either! If you need to put a delay between recurring
events, you should use `delay` option of `register_event`
statement.

It can also load node's CPU for specified time. This is defined
with `cpu` statement. CPU load time is defined by results of block
passed to the statement. The parameter passed to the block
represents CPU to which this work is assigned. Performance of
this CPU can be checked using `cpu.performance`.

    cpu do |cpu|
      (10000 / cpu.performance).miliseconds
    end


Time values defined by `delay_for` and returned by the `cpu` block
can be random.

#### Events and Handlers

Defining process one can use `on_event` statement, to define
process behavior when an event occurs. Process can also register
event's occurence using `register_event` statement. This is
recommended method of describing processes behavior, also
recurring behaviors. The following example will repeat sending
data 10 times.

    new_process :wget do
      sent = 0
      on_event :send do
        cpu do |cpu|
          (150 / cpu.performance).miliseconds
        end
        sent += 1
        register_event :send, delay: 5.miliseconds if sent < 10
      end

      register_event :send
    end

The optional `delay:` option of the `register_event` statement
will cause the event to be registered with specified delay. Thus
the above example will register the `:send` events with 5
milisecond gaps. By default events are registered immediatelly,
without any delay.

All statements that can be used to describe processe's behavior
can also be used inside `on_event` statement. In fact the event
handlers are preferred place to describe behavior of a process.

#### Reading simulation clock

It is possible to check value of simulation clock at which given event
is being handled. This clock has the same value inside the whole block
handling the event and it equals to the time at which the event handling
started (not the time when the event occured/was registered!). The clock
can be read using:

* `event_time` method that returns clock value

Value returned by the `event_time` method does not change inside
the event handling block even if you used `delay_for` or `cpu`
statements in this block before the `event_time` method was
called. But if you call `event_time inside the `cpu` block it
will return the time at which this block is valueted i.e. time at
which the CPU processing starts.

Concluding:

* the `event_time` method can be used inside each block inside program
  definition,
* inside the whole block it returns the same value -- time when the event
  handling (i.e. block evaluation) started,
* if called inside a block which is inside a block... it returns time at
  which the most inner event handling (block evaluation) started.

If you need to measure time between two occurrences in whatever you
simulate, just define these occurences as two separate events in
the model. Then you will be able to read the time at which
handling of each of these events started.

#### Communication

##### Sending data

A process can send data to another process using its name as
destination address.

    new_process :sender1 do
      send_data to: :receiver, size: 1024.bytes, type: :request, content: 'anything useful for your model'
    end

Data will be sent to process called `:receiver`, size will be
1024 bytes, `type` and `content` of the data can be set to anything
considered useful.

##### Receiving data

Every process is capable of receiving data, but by default the
data will be dropped and a warning issued. To process received
data, process must define event handler for `:data_received`
event.

    on_event :data_received do |data|
      cpu do |cpu|
        (data.size / cpu.performance).miliseconds
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
          (150 / cpu.performance).miliseconds
        end
        send_data to: opts[:target], size: 1024.bytes, type: :request, content: sent
        sent += 1
        register_event :send, delay: 5.miliseconds if sent < 10
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
 * `stats_save value, tag [, group_name] saves given value and current
   time

The optional `group_name` parameter allows one to group
statistics by additional name, e.g. name of specific process
(apache1, apache2, apache2, ...) in which they were collected.

Simulator automatically collects statistics for resource usage
(subsequent CPUs and net segments).

The statistics collected by `stats` statements can be obtained
after simulation with one of the following methods mentioned at
the beginning:

    model.stats_print
    model.stats_summary
    model.stats_data

##### Variabeles, Conditions, Loops

As shown in examples above (see model of wget), variables can be
used to steer behavior of a process. Their visibility should be
intuitive.  Don't use Ruby's instance variables -- `@something`
-- didn't test it, but no guarantee given!

You can also get name of current process from `process.name`.

Using conditional statements is encouraged wherever it is useful.
Using loops is definitely NOT encouraged. It can (and most probably
will) create long event queues which will slow down simulation.
You should rather use recurring events, as in the example with
wget model.

### Programs

Programs can be used to define the same logic used in a numebr of
processes. Their names can be the used to define processes.
Behavior of programs ca be described using the same statemets
that are used to describe processes.


    program :waiter do |time|
      delay_for time: time
    end

    program :worker do |volume|
      cpu do |cpu|
        ( (volume * volume).in_bytes / cpu.performance ).miliseconds
      end
    end

These two programs can be used to define processes:

    new_process program: waiter, args: 100.miliseconds
    new_process program: worker, args: 2000.bytes

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

    net :lan, bw: 1024.bps
    net :subnet1, bw: 20480.bps

#### Routes

Routes are used to define which `net` segments should be traversed
by data transmitted between two given `node`s. Routes can be
one-way (default) or two-way.

    route from: :laptop, to: :node02, via: [ :net01, :net02 ]
    route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: true
    route from: :node06, to: :node07, via: [ :net07, :net01 ], twoway: :true

Communication between processes located on different nodes
requires a route defined between the nodes. If there is more then
one route between a pair of nodes, random one is selected.  A
node can communicate with itself without any route defined and
without traversing any `net` segemtns

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
topology of resources. The same application can be mapped to
different resources in different ways. The same resource set can
be used for different applications.

### Units

Simulator operates on three kinds of values:

 * data volume
 * network bandwidth
 * time

For each value one can use specific measurement units:

  * for data volume
    * bits
    * bytes
  * for network bandwidth
    * bps (bits per second)
    * Bps (bytes per second)
  * for time:
    * microseconds
    * miliseconds
    * seconds
    * minutes
    * hours
    * days (24 hours)

In every place where data volume should be given, it can be
defined using expressions like

    1024.bytes
    128.bits

Similarly network bandwidth can be defined using

    128.Bps
    1024.bps

Finally, if time should be given, one should use a unit, to
ensure correct value, e.g.

    10.seconds
    100.microseconds
    2.hours

For values returned from simulator, to ensure value in correct
units use `in_*` methods, e.g.

    data.in_bytes
    time.in_seconds

So to define that CPU load time in miliseconds should be equal to
10 * data volume in bytes, use:

    cpu do |cpu|
      (data.size.in_bytes * 10).miliseconds
    end

Every measurement unit has its equivalent `in_*` method.

### Example

Below thete is a simble but complete example model of two
applications: `wget` sending subsequent requests to specified
process and `apache` responding to received requests. 

The `wget` program accepts parameters describing its target
(destination of requests) -- `opts[:target]` and count of
requests to send -- `opts[:count]`. The paremeters are defined
when new process is defined using this program.  The `apache`
program takes no additional parameters.

Two client processes are started using program `wget`: `client1`
and `client2`. Using `apache` program one server is started:
`server`. Application uses two nodes: `desktop` with one slower
processor and `gandalf` with one faster CPU. The nodes are
connected by two nets and one two-way route.  Both clients are
assigned to the `desktop` node while server is run on `gandalf`.

The clients are mapped to the `desktop` node and the server is
assigned to `gandalf`.

Logs are printed to STDOUT and statistics are collected. Apache
`stats` definitions allow to observe time taken by serving
requests. Client `stats` count served requests and allow to
verify if aresponses were received for all sent requests.

The created model is run and its statistics are printed.

    require 'rbsim'

    model = RBSim.model do

      program :wget do |opts|
        sent = 0
        on_event :send do
          cpu do |cpu|
            (150 / cpu.performance).miliseconds
          end
          send_data to: opts[:target], size: 1024.bytes, type: :request, content: sent
          sent += 1
          register_event :send, delay: 5.miliseconds if sent < opts[:count]
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
            (100 * data.size.in_bytes / cpu.performance).miliseconds
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

      net :net01, bw: 1024.bps
      net :net02, bw: 510.bps

      route from: :desktop, to: :gandalf, via: [ :net01, :net02 ], twoway: true

      put :server, on: :gandalf
      put :client1, on: :desktop
      put :client2, on: :desktop

    end

    model.run

    model.stats_print

This model will print the following statistics for application
and its resources:



    ================================================================================
    STATISTICS:

    Time: 1.461264s

    APPLICATION
    --------------------------------------------------------------------------------
    Counters
    ------------------------------
      client1
        request_served	: 10
      client2
        request_served	: 10
    Durations
    ------------------------------
      server
        apache	:  1.460s (99.9135%)

    RESOURCES
    --------------------------------------------------------------------------------
    Counters
    ------------------------------
    Durations
    ------------------------------
      CPU
        desktop	:  0.020s ( 1.3687%)
        gandalf	:  1.460s (99.9135%)
      NET
        net01	:  0.002s ( 0.1204%)
        net02	:  0.004s ( 0.2409%)
    ================================================================================


## Custom Logger 

TODO

## Custom Statistics Collector

TODO

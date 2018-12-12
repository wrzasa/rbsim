RBSim -- software technical reference
=====

This is a technical description of the RBSim software package.

RBSim is a simulation tool designed for analysis of architecture of
concurrent and distributed applications. Application should be described
using convenient Ruby-based DSL. Simulation is based on Timed Colored
Petri nets designed by K. Jensen, thus ensuring reliable analysis. Basic
statistics module is included.

In order to provide quick overview of the method here you will
find example usage of RBSim. Detailed description of model,
simulation and processing statistics can be found in the
following sections.


# Example

Below there is a simple but complete example model of two
applications: `wget` sending subsequent requests to specified
process and `apache` responding to received requests.

The `wget` program accepts parameters describing its target
(destination of requests) -- `opts[:target]` and count of
requests to send -- `opts[:count]`. The parameters are defined
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
verify if responses were received for all sent requests.

The created model is run and its statistics are printed.

The `model.rb` file contains model of the application and resources
described with DSL:

```ruby
program :wget do |opts|
  sent = 0
  on_event :send do
    cpu do |cpu|
      (150 / cpu.performance).miliseconds
    end
    send_data to: opts[:target], size: 1024.bytes,
              type: :request, content: sent
    sent += 1
    register_event :send, delay: 5.miliseconds if sent < opts[:count]
  end

  on_event :data_received do |data|
    log "Got data #{data} in process #{process.name}"
    stats event: :request_served, client: process.name
  end

  register_event :send
end

program :apache do
  on_event :data_received do |data|
    stats_start server: :apache, name: process.name
    cpu do |cpu|
      (100 * data.size.in_bytes / cpu.performance).miliseconds
    end
    send_data to: data.src, size: data.size * 10, 
              type: :response, content: data.content
    stats_stop server: :apache, name: process.name
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
```

Creating empty subclass of `RBsim::Experiment` in `rbsim_example.rb`
file is sufficient to start simulation:

```ruby
class Experiment < RBSim::Experiment
end
```

The simulation can be started with the following code:

```ruby
require './rbsim_example'

params = { }

sim = Experiment.new
sim.run './model.rb', params
sim.save_stats 'simulation.stats'
```

The `save_stats` method appends statistics to the specified file.
Statistics saved can be loaded with:

```ruby
all_stats = Experiment.read_stats 'simulation.stats'
```

The `all_stats` will be an iterator yielding objects of class `Experiement`,
so statistics of first experiment can be accessed using:

```ruby
all_stats.first.app_stats  # application statistics
all_stats.first.res_stats  # resource statistics
```

Processing statistics into required results can be implemented in the
`Experiement` class (so far this class was empty) like this:

```ruby
class Experiment < RBSim::Experiment

  def print_req_times_for(server)
    app_stats.durations(server: server) do |tags, start, stop|
      puts "Request time #{(stop - start).in_miliseconds} ms. "
    end
  end

  def mean_req_time_for(server)
    req_times = app_stats.durations(server: server).to_a
    sum = req_times.reduce(0) do |acc, data|
      _, start, stop = *data
      acc + stop - start
    end
    sum / req_times.size
  end

end
```

Then, the statistics can be conveniently used like this:

```ruby
all_stats = Experiment.read_stats 'simulation.stats'
first_experiment = all_stats.first
first_experiment.print_req_times_for(:apache)
puts "Mean request time for apache: "
puts "#{first_experiment.mean_req_time_for(:apache).in_seconds} s"
```

You can of course iterate over subsequent experiments to get statistics
involving a number of different tests.

In next sections you will find description of subsequent parts of the
RBSim tool.

## Usage

There are two ways to create model. Preferred one is to subclass the
`Experiment` class. But it is also possible to directly create model
with RBSim class.

### Using `RBsim::Experiment` class

Create a class that inherits `RBsim::Experiment` class. 

```ruby
 class MyTests < RBSim::Experiment
 end
```

Thereafter you can use it to load model and perform simulations:

```ruby
 sim = MyTests.new
 sim.run 'path/to/model_file.rb'
```

Finally, you can save statistics gathered from simulation to a file:

```ruby
 sim.save_stats 'file_name.stats'
```

If the file exists, new statistics will be appended at its end.

The saved statistics can be later loaded and analyzed with the same
class inheriting from the `RBSim::Experiment`:

```ruby
 stats = MyTests.read_stats 'file_name.stats'
```

The `RBSim.read_stats` method will return an array of `MyTests` objects
for each experiment saved in the file. The objects can then be used to
process statistics as described further.

You can limit simulation time by setting `sim.time_limit` before you
start simulation. In order to use time units you need to `require
'rbsim/numeric_units'` before.

```ruby
sim.time_limit = 10.seconds
```

RBSim uses coarse model of network transmission. If you application
requires more precise estimation of network transmission time, you can
set:

```ruby
sim.data_fragmentation = number_of_fragments
```

This will cause each data package transmitted over the network to be
divided into at most `number_of_fragments` (but not smaller then 1500B).
If your application efficiency depends significantly on numerous data
transmissions influencing each other this may improve accuracy, but it
will also increase simulation time. If this is not sufficient and
efficiency of your application depends on network transmission time
(network bounded), not on application logic and logic of communication
in the system, you should probably revert to a dedicated network
simulator.

### Using `RBSim.model`

You can also define your model using `RBSim.model` method:

```ruby
model = RBSim.model some_params do |params|
  # define your model here
  # use params passed to the block
end
```

Or read the model from a file:

```ruby
model = RBSim.read file_name, some_params_hash
```

`some_params_hash` will be available in the model loaded from the file
as `params` variable.


Run simulator:

```ruby
model.run
```

When simulation is finished, the statistics can be obtained with
`model.stats` method.

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

```ruby
new_process :sender1 do
  delay_for time: 100
  cpu do |cpu|
    (10000 / cpu.performance).miliseconds
  end
end
```

First parameter of the statement is the process name which must
be unique in the whole model. The block defines behavior of the process
using statements described below.

#### Delay and CPU Load

A process can do nothing for some time. This is specified with
`delay_for` statement.

```ruby
delay_for 100.seconds
```

or

```ruby
delay_for time: 100.seconds
```

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

```ruby
cpu do |cpu|
  (10000 / cpu.performance).miliseconds
end
```

Time values defined by `delay_for` and returned by the `cpu` block
can be random.

#### Events and Handlers

Defining process one can use `on_event` statement, to define
process behavior when an event occurs. Process can also register
event's occurence using `register_event` statement. This is
recommended method of describing processes behavior, also
recurring behaviors. The following example will repeat sending
data 10 times.

```ruby
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
```

The optional `delay:` option of the `register_event` statement
will cause the event to be registered with specified delay. Thus
the above example will register the `:send` events with 5
milisecond gaps. By default events are registered immediatelly,
without any delay.

All statements that can be used to describe processe's behavior
can also be used inside `on_event` statement. In fact the event
handlers are preferred place to describe behavior of a process.

#### Reusable functions

The model allows to define functions that can be called from blocks
defining event handlers. The functions can hol reusable code useful
in one or more then handlers. Functions are defined using `function`
statement like this:

```ruby
function :do_something do
  # any statements allowed in
  # event handler blocks can be
  # put here
end
```

Functions take parameters defined as usually for Ruby blocks:

```ruby
function :do_something_with_params do |param1, param2|
  # any statements allowed in
  # event handler blocks can be
  # put here
end
```

They return values like Ruby methods: either defined by `return`
statement or the last stateent in the function block.

##### Note on `def`

You don't have to understand this. You don't even have to read this
unless you insist on using Ruby's `def` defined methods instead of above
described `function` statement.

You can use Ruby `def` statement to define reusable code in the model,
but it is **not recommended** unless you know exactly what you are
doing! The `def` defined methods will be accessible from event handler
blocks, but when called, they will be evaluated in the context in which
they were defined, not in the context of the block calling the function.
Consequently, any side effects caused by the function (like
`register_event`, `log`, `stat` or anything the DSL gives you) will be
reflected in the wrong context! Using `def` defined methods is safe only
if they are strictly functional-like -- i.e. cause no side effects.

#### Reading simulation clock

I am not convinced that this is necessary, but for now it is available.
Read and understand all this section if you think you need this.

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

The truth is that you should not need this. Not ever. For instance if
you need to model timeout waiting for a response, just register a
timeout event when you send request and inside this event either mark
request as timed out or do nothing it response was receivd before.

#### Communication

##### Sending data

A process can send data to another process using its name as
destination address.

```ruby
new_process :sender1 do
  send_data to: :receiver, size: 1024.bytes, type: :request, content: 'anything useful for your model'
end
```

Data will be sent to process called `:receiver`, size will be
1024 bytes, `type` and `content` of the data can be set to anything
considered useful.

##### Receiving data

Every process is capable of receiving data, but by default the
data will be dropped and a warning issued. To process received
data, process must define event handler for `:data_received`
event.

```ruby
on_event :data_received do |data|
  cpu do |cpu|
    (data.size / cpu.performance).miliseconds
  end
end
```

The parameter passed to the event handler (`data` in the example
above) contains a Hash describing received data.

```ruby
{ src: :source_process_name,
  dst: :destination_process_name,
  size: data_size,
  type: 'a value_given_by_sender',
  content: 'a value given by sender' }
```

The complete example of wget -- sending requests and receiving
responses can look like this:

```ruby
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
    stats event: :request_served, where: process.name
  end

  register_event :send
end
```

##### Logs and statistics

The `log` statement can be used in the process description, to
send a message to logs (by default to STDOUT).

The `stats` statements can be used to collect running statistics.

 * `stats_start tags` marks start of an activity described by `tags`
 * `stats_stop tags` marks start of an activity described by `tags`
 * `stats tags` marks that a counter marked by `tags` should be
   incremented
 * `stats_save value, tags` saves given value and current time

The `tags` parameter allows one to group
statistics by required criteria, e.g. name of specific process
(apache1, apache2, apache2, ...) in which they were collected, action
performred by the process (begin_request, end_request) etc. The
parameter should be a hash and it is your responsibility to design
structure of these parameters to be able to conveniently collect
required events.

Simulator automatically collects statistics for resource usage
(subsequent CPUs and net segments).

##### Variables, Conditions, Loops

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


```ruby
program :waiter do |time|
  delay_for time: time
end

program :worker do |volume|
  cpu do |cpu|
    ( (volume * volume).in_bytes / cpu.performance ).miliseconds
  end
end
```

These two programs can be used to define processes:

```ruby
new_process program: waiter, args: 100.miliseconds
new_process program: worker, args: 2000.bytes
```

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

```ruby
node :laptop do
  cpu 1000
  cpu 1000
  cpu 1000
end
```

The performance defined here, can be used in `cpu` statement in
process description.


#### Nets

Nets used in communication are defined with `net` statement with
name as parameter and a Hash definind other parameters of the
segment. The most important parameter of each net segmetn is its
bandwidth:

```ruby
net :lan, bw: 1024.bps
net :subnet1, bw: 20480.bps
```

Additionally it is possible to specify probability that a packet
transmitted over this network will be dropped. Currently, each message
sent between two processes is treated as a single packet, so this
probability will apply to dropping the whole message -- the message will
be sent, but nothing will be received. By default drop probability is
set to 0 and all sent messages are delivered. 

There are two ways to define probability drop probability. First,
specify a `Float` number between 0 and 1. The packets will be dropped
with this this probability and uniform distribution:

```ruby
net :lan, bw: 1024.bps, drop: 0.01
```

Second, it is possible to define a block of code. That block will be
evaluated for each packet transmitted over this network and should
return true if packet should be dropped and false otherwise. This block
can use Ruby's `rand` function and any desired logic to produce require
distribution of dropped packets. Fo example, to drop packets according
to exponential distribution with lambda = 2:

```ruby
net :lan, bw: 1024.bps, drop: ->{ -0.5*Math.log(rand) < 0.1 }
```

Currently, it is not possible to make probability of dropping a packet
dependent on dropping previous packets.

#### Routes

Routes are used to define which `net` segments should be traversed
by data transmitted between two given `node`s. Routes can be
one-way (default) or two-way.

```ruby
route from: :laptop, to: :node02, via: [ :net01, :net02 ]
route from: :node04, to: :node05, via: [ :net07, :net01 ], twoway: true
route from: :node06, to: :node07, via: [ :net07, :net01 ], twoway: :true
```

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

```ruby
put :wget, on: :laptop
put :server1, on: :gandalf
```

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

```ruby
1024.bytes
128.bits
```

Similarly network bandwidth can be defined using

```ruby
128.Bps
1024.bps
```

Finally, if time should be given, one should use a unit, to
ensure correct value, e.g.

```ruby
10.seconds
100.microseconds
2.hours
```

For values returned from simulator, to ensure value in correct
units use `in_*` methods, e.g.

```ruby
data.in_bytes
time.in_seconds
```

So to define that CPU load time in milliseconds should be equal to
10 * data volume in bytes, use:

```ruby
cpu do |cpu|
  (data.size.in_bytes * 10).miliseconds
end
```

Every measurement unit has its equivalent `in_*` method.

## Using simulation statistics

The way of obtaining statistics depends on the method used to create
simulation. The most convenient is to use subclass of the
`RBSim::Experiment` class, but it can also be done with the simulation
performed with `RBSim` class.

### Statistics with subclass of `RBSim::Experiment`

The `RBSim::Experiment` class provides convenient method to obtain
simulation statistics and its subclass created to run simulation is a
natural place to implement own methods that process the statistics into
required collective results.

There are two methods available for every instance method in a subclass
of the `RBSim::Experiment` class. The `app_stats` gives access to
statistics concerning modeled application, and the `res_stats`
contains statistics concerning used resources, the ones automatically
collected by the simulator. 

For application stats as well as for resource stats the actual data is
available with three iterators, for three types of
collected statistics:

* data from basic counters collected using `stats`
statement in the model can be obtained with `counters` iterator
* data from duration statistics collected with `stats_start` and
  `stats_stop` statements can be obtained with `duration` iterator
* data from value stats saved with `stats_save` are available via
  `values` iterator.

Each iterator accepts optional parameter describing filters, so it is
possible to limit amount of data that should be processed. The filters
allow to select required values on the basis of parameters passed to the
`stats_*` statements in the model. For example, in order to get
durations of `operation` called `:update` on can use the following
snippet:

```ruby
app_stats.durations(operation: :update)
```

assuming that the data are collected in the model with statements

```ruby
stats_start operation: :update
```

and

```ruby
stats_stop operation: :update
```

Depending on the type of collected data (counters, durations, values)
different data are passed by the iterator.

#### Values of counters

Counters are grouped according to parameters (tags) passed to the
`stats` statement in the model. Every time such statement is reached
during simulation, current values of the simulation clock is saved. The
`counters` iterator yields two arguments: `tags` and array of timestamps
when counters with these tags was triggered.

```ruby
app_stats.counters(event: :finished) do |tags, timestamps|
  # do something with :finished events
  # if you need you can check the other
  # tags saved with these events
end
```

#### Duration times

Duration times are saved from the model using `stats_start` and
`stats_stop` statements. They are also grouped according to the tags
passed to these statements. Data can be subsequently filtered using
these tags and the `durations` iterator yields three values: `tags`,
`start_time`, `stop_time`, where start and stop times are timestamps at
which simulation reached corresponding statement. 

For example if an operation in a model is braced with statement:

```ruby
stats_start operation: :update
```

and

```ruby
stats_stop operation: :update
```

duration of this operation can be obtained using the following
statement:

```ruby
app_stats.durations(operation: :update) do |tags, start, stop|
  # do something with the single duration
  # you can use the values of the tags
end
```

If there were more then one event with the same tags save, the block
will be yielded for each of them. Similarly, if there were additional
tags set for the `stats_*` statements, the block will be yielded for
each of them.

#### Values

Values (e.g. queue length) can be saved while simulation using
`stats_save` statement with require tags. The save values are grouped
using tags and time at which they were saved. The `values` iterator
yields three parameters: `tags`, `timestamp`, `values` where values is a
list of values saved for the same tags and the same time.

#### Statistics of resources

Statistics of resources are automatically collected by simulator in a
predefined way. They are available in the `RBSim::Experiment` subclass
with the `res_stats` method. They are grouped by the predefined tags
that allow to identify resource that generated specific reading and type
of the value.

* CPU usage can be obtained using duration events tagged with `resource:
  'CPU'` tag, and also with `node:` with name of the node the CPU
  belongs to,
* network usage for subsequent net segments can be obtained with
  duration iterator using network `resource: 'NET'` tag; these values
  are also tagged with and `name:` tag corresponding to the name of the
  network segment,
* number of packages dropped by a network segment is available via
  `counter` iterator using tags `event: 'NET DROP'` with additional
  `net:` tag corresponding to the name of the segment,
* waiting time for data packages that were transmitted over the network,
  but not yet handled by a busy processes are tagged with: `resource
  'DATAQ WAIT` and `process:` tag corresponding to name of the receiving
  process.
* length of the queue that holds data that were transmitted over the
  network but not yet received by a busy process can be read with
  `values` counter using `resource: 'DATAQ LEN'` tag with additional tag
  `process:` corresponding to the process name.

If for a more complicated model of resources there is a need to
additionally group the resources, it is possible to put additional tags
to 

* nets
* cpus
* processes

and these tags will be saved together with statistics corresponding to
these processes. So it is e.g. possible to create a group of processes
of the same type:

```ruby
new_process :apache1, program: :webserver, tags { type: :apache }
new_process :apache2, program: :webserver, tags { type: :apache }
```

and then obtain queue lengths for all of them with:

```ruby
res_stats.values(resource: 'DATAQ LEN', type: :apache)
```

### Statistics when using `RBSim.model`

The only difference from `RBSim::Experiment` is the way to obtain
objects holding the actual statistics. When model was created using
`RBSim.model` or `RBSim.read` and saved in a `model` variable, the
statistics can be obtained using  `model.stats` method. The method
returns hash with two elements. Under `:app_stats` key there is the same
object that is available in a subclass of `RBSim::Experiment` using
method `app_stats`. Similarly there is `:res_stats` key holding the
the resource statistics.


# Copyright

Copyright (c) 2014-2018 Wojciech Rząsa. See LICENSE.txt for further details. Contact me if interested in different license conditions.

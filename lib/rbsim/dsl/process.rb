module RBSim
  class DSL
    def new_process(name, opts = nil, &block)
      ProcessDSL.new_process(@model, name, opts, &block)
    end
  end

  class ProcessDSL
    UnknownProgramName = Class.new RuntimeError
    NeitherBlockNorProgramGiven = Class.new RuntimeError

    attr_reader :process

    # Create new process.
    # +name+ process name
    # +opts+ +{ program: name_of_program_to_run, args: args_to_pass_to_program_block }+
    # +block+ block defining new process (if given +opts+ are ignored)
    def self.new_process(model, name, opts = nil, &block)
      args = nil
      program = nil
      unless block_given?
        program = opts[:program]
        raise NeitherBlockNorProgamGiven.new("for new_process #{name}") if program.nil?
        args = opts[:args]
        block = model.programs[program]
        raise UnknownProgramName.new("#{program} for new_process #{name}") if block.nil?
      end
      process = Docile.dsl_eval(ProcessDSL.new(model, name, program), args, &block).process
      model.processes[name] = process
    end

    def initialize(model, name, program, process = nil)
      @name = name
      @model = model
      @program = program
      @process = process
      @process = Tokens::ProcessToken.new(@name, @program) if @process.nil?
    end

    def on_event(event, &block)
      # Cannot use self as eval context and
      # must pass process because after clonning in TCPN it will be
      # completely different process object then it is now!
      handler = proc do |process, args|
        process.functions.each do |name, definition|
          # This is actually a kind of hack... but there is
          # no other way to hit exactly this class with define_method, since
          # almost all other methods from this class are removed by docile.
          # Therefore every attempt to do metaprogramming on objects of this class
          # hit the objects to whom this class forwards method calls...
          # But this way we actually can define required methods that will operate
          # in the context of proper object representing a process and that will
          # cause side effects (e.g. changes in event queue) in proper objects.
          Docile::FallbackContextProxy.__send__ :define_method, name, definition
        end
        changed_process = Docile.dsl_eval(ProcessDSL.new(@model, @name, @program, process), args, &block).process
        process.functions.each do |name, definition|
          # remove newly defined methods not to mess things up in the Docile::FallbackContextProxy
          # unless removed, these methods would be available for the other processes!
          Docile::FallbackContextProxy.__send__ :undef_method
        end
        changed_process
      end
      @process.on_event(event, &handler)
    end

    def function(name, &block)
      @process.function name, &block
    end

    # register_event name, delay: 100, args: { event related args }
    def register_event(event, opts = {})
      args = opts[:args]
      delay = opts[:delay] || 0
      @process.enqueue_event(:register_event, event: event, delay: delay, event_args: args)
    end

    def cpu(&block)
      @process.enqueue_event(:cpu, block: block)
    end

    def delay_for(args)
      if args.kind_of? Numeric
        args = { time: args }
      end
      @process.enqueue_event(:delay_for, args)
    end

    def send_data(args)
      @process.enqueue_event(:send_data, args)
    end

    def log(message)
      @process.enqueue_event(:log, message)
    end

    def stats_start(tags)
      @process.enqueue_event(:stats_start, tags)
    end

    def stats_stop(tags)
      @process.enqueue_event(:stats_stop, tags)
    end

    def stats(tags)
      @process.enqueue_event(:stats, tags)
    end

    def stats_save(value, tags)
      params = { tags: tags, value: value }
      @process.enqueue_event(:stats_save, params)
    end

    def new_process(name, args = nil, &block)
      constructor = proc do |args|
        new_process = self.class.new_process(@model, name, args, &block)
        new_process.node = @process.node
        new_process
      end
      @process.enqueue_event(:new_process, constructor_args: args, constructor: constructor)
    end

    # returns time at which the event occured
    def event_time
      @model.simulator.clock
    end
  end
end


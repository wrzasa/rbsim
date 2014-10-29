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
      #@process = HLModel::Process.new(@name, @program)
      @process = ProcessToken.new(@name, @program) if @process.nil?
    end

    def with_event(event, &block)
      # Cannot use self as eval context and
      # must pass process because after clonning in TCPN it will be 
      # completely different process object then it is now!
      handler = proc do |process, args|
        Docile.dsl_eval(ProcessDSL.new(@model, @name, @program, process), args, &block).process
      end
      @process.with_event(event, &handler)
    end

    def register_event(event, args)
      @process.register_event(event, args)
    end

    def cpu(&block)
      @process.register_event(:cpu, block: block)
    end

    def delay_for(args)
      if args.instance_of? Fixnum
        args = { time: args }
      end
      @process.register_event(:delay_for, args)
    end

    def send_data(args)
      @process.register_event(:send_data, args)
    end

    def new_process(name, args = nil, &block)
      self.class.new_process(@model, name, args, &block)
    end

  end
end


module RBSim
  class DSL
    def initialize(model)
      @model = model
    end

    def node(name, &block)
      @model.nodes << Docile.dsl_eval(NodeDSL.new(name), &block).build
    rescue => e
      puts e
      raise
    end

    def net(name, args = {})
      bw = args[:bw]
      delay = args[:delay] || 0
      drop = args[:drop] || 0
      tags = args[:tags] || {}
      @model.nets << Tokens::NetToken.new(name, bw, delay, drop, tags)
    end

    def route(args = {})
      twoway = if args[:twoway] || args[:twoway] == :true
                 true
               else
                 false
               end
      @model.routes << HLModel::Route.new(args[:from], args[:to], args[:via], twoway)
    end
  end

  class NodeDSL
    def initialize(name)
      @name = name
      @cpus = []
    end

    def cpu(performance, args = {})
      tags = args[:tags] || {}
      @cpus << Tokens::CPUToken.new(performance, nil, tags)
    end

    def build
      HLModel::Node.new(@name, @cpus)
    end

  end
end

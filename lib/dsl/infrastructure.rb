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
      bw = args[:bw] || 0
      delay = args[:delay] || 0
      @model.nets << HLModel::Net.new(name, bw, delay)
    end
  end

  class NodeDSL
    def initialize(name)
      @name = name
      @cpus = []
    end

    def cpu(performance)
      @cpus << HLModel::Node::CPU.new(performance)
    end

    def build
      HLModel::Node.new(@name, @cpus)
    end

  end
end

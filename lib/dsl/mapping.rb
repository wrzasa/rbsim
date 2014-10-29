module RBSim
  class DSL
    IncorrectMapping = Class.new RuntimeError

    def put(process_name, opts = nil)
      if !process_name.instance_of?(Hash) && opts.nil? 
        raise IncorrectMapping.new("Does not define node for proces #{process_name}")
      end

      if process_name.instance_of? Hash
        opts = process_name
      else
        opts[:process] = process_name
      end

      process = opts[:process]
      node = opts[:on]

      if process.nil?
        msg = " to put on node #{node}" unless node.nil?
        raise IncorrectMapping.new("Does not define process#{msg}")
      end
      if node.nil?
        raise IncorrectMapping.new("Does not define node for proces #{process}")
      end

      @model.mapping[process] = node

    end
  end
end


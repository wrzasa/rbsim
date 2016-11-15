module RBSim
  class DSL
    # program statement just remembers
    # program's block under specified name,
    # to be used later when defining/starting processes
    def program(name, &block)
      @model.programs[name] = block
    end
  end
end

module Stackup
  class Stack
    attr_accessor :stack

    def initialize(name)
      cf = Aws::CloudFormation.new
      @stack = cf.stacks[name]
    end

    def deployed?
      stack.exists?
    end

  end
end

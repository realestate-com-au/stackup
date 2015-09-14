module Stackup
  class Stack
    attr_accessor :stack, :cf, :template

    def initialize(name, template)
      @cf = Aws::CloudFormation.new
      @stack = cf.stacks[name]
      @template = template
    end

    def deployed?
      stack.exists?
    end

    def valid?
      response = cf.validate_template(template)
      response[:code].nil?
    end

  end
end

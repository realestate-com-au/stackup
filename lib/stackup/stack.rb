module Stackup
  class Stack
    attr_accessor :stack, :name, :cf, :template

    def initialize(name, template)
      @cf = Aws::CloudFormation.new
      @stack = cf.stacks[name]
      @template = template
      @name = name
    end

    def create
      response = @cf.create_stack({
        stack_name: name,
        template_body: template,
        disable_rollback: true
        })
      !response[:stack_id].nil?
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

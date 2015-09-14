require 'set'

module Stackup
  class Stack
    attr_accessor :stack, :name, :cf, :template

    def initialize(name, template)
      @cf = Aws::CloudFormation::Client.new
      @stack = Aws::CloudFormation::Stack.new(name: name, client: cf)
      @monitor = Stackup::Monitor.new(@stack)
      @template = template
      @name = name
    end

    def create
      response = cf.create_stack({
        stack_name: name,
        template_body: template,
        disable_rollback: true
        })
      !response[:stack_id].nil?
    end

    def deployed?
      !stack.stack_status.nil?
    rescue Aws::CloudFormation::Errors::ValidationError => e
      false
    end

    def valid?
      response = cf.validate_template(template)
      response[:code].nil?
    end

  end
end

require "set"

module Stackup
  class Stack

    attr_reader :stack, :name, :cf, :monitor
    SUCESS_STATES = ["CREATE_COMPLETE", "DELETE_COMPLETE", "UPDATE_COMPLETE"]
    FAILURE_STATES = ["CREATE_FAILED", "DELETE_FAILED", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "UPDATE_ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_FAILED"]
    END_STATES = SUCESS_STATES + FAILURE_STATES

    def initialize(name)
      @cf = Aws::CloudFormation::Client.new
      @stack = Aws::CloudFormation::Stack.new(:name => name, :client => cf)
      @monitor = Stackup::Monitor.new(@stack)
      @name = name
    end

    def status
      stack.stack_status
    rescue Aws::CloudFormation::Errors::ValidationError => e
      nil
    end

    def create(template, parameters)
      response = cf.create_stack(:stack_name => name,
                                 :template_body => template,
                                 :disable_rollback => true,
                                 :capabilities => ["CAPABILITY_IAM"],
                                 :parameters => parameters)
      wait_for_events
      !response[:stack_id].nil?
    end

    def update(template, parameters)
      return false unless deployed?
      if stack.stack_status == "CREATE_FAILED"
        puts "Stack is in CREATE_FAILED state so must be manually deleted before it can be updated"
        return false
      end
      if stack.stack_status == "ROLLBACK_COMPLETE"
        deleted = delete
        return false if !deleted
      end
      response = cf.update_stack(:stack_name => name, :template_body => template, :parameters => parameters, :capabilities => ["CAPABILITY_IAM"])
      wait_for_events
      !response[:stack_id].nil?
    end

    def delete
      return false unless deployed?
      cf.delete_stack(:stack_name => name)
      status = wait_for_events
      fail UpdateError, "stack delete failed" unless status == "DELETE_COMPLETE"
      true
    rescue Aws::CloudFormation::Errors::ValidationError
      puts "Stack does not exist."
    end

    def deploy(template, parameters = [])
      if deployed?
        update(template, parameters)
      else
        create(template, parameters)
      end
    rescue Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
    end

    def outputs
      puts stack.outputs.flat_map { |output| "#{output.output_key} - #{output.output_value}" }
    end

    def deployed?
      !stack.stack_status.nil?
    rescue Aws::CloudFormation::Errors::ValidationError => e
      false
    end

    def valid?(template)
      response = cf.validate_template(template)
      response[:code].nil?
    end

    class UpdateError < StandardError
    end

    private

    # Wait (displaying stack events) until the stack reaches a stable state.
    #
    def wait_for_events
      loop do
        display_new_events
        status = stack.stack_status
        return status if status =~ /_(COMPLETE|FAILED)$/
        sleep(5)
      end
    end

    def display_new_events
      monitor.new_events.each do |e|
        ts = e.timestamp.localtime.strftime("%H:%M:%S")
        fields = [e.logical_resource_id, e.resource_status, e.resource_status_reason]
        puts("[#{ts}] #{fields.compact.join(' - ')}")
      end
    end
  end
end

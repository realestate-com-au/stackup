require "aws-sdk-resources"
require "stackup/monitor"

module Stackup
  class Stack

    SUCESS_STATES = ["CREATE_COMPLETE", "DELETE_COMPLETE", "UPDATE_COMPLETE"]
    FAILURE_STATES = ["CREATE_FAILED", "DELETE_FAILED", "ROLLBACK_COMPLETE", "ROLLBACK_FAILED", "UPDATE_ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_FAILED"]
    END_STATES = SUCESS_STATES + FAILURE_STATES

    def initialize(name, client_or_options = {})
      @name = name
      if client_or_options.is_a?(Hash)
        @cf_client = Aws::CloudFormation::Client.new(client_or_options)
      else
        @cf_client = client_or_options
      end
      @cf_stack = Aws::CloudFormation::Stack.new(:name => name, :client => cf_client)
      @monitor = Stackup::Monitor.new(@cf_stack)
      @monitor.new_events # drain previous events
    end

    attr_reader :name, :cf_client, :cf_stack, :monitor

    def status
      cf_stack.stack_status
    rescue Aws::CloudFormation::Errors::ValidationError
      nil
    end

    def exists?
      !!status
    end

    def create(template, parameters)
      cf_client.create_stack(
        :stack_name => name,
        :template_body => template,
        :disable_rollback => true,
        :capabilities => ["CAPABILITY_IAM"],
        :parameters => parameters
      )
      status = wait_for_events

      fail CreateError, "stack creation failed" unless status == "CREATE_COMPLETE"
      true

    rescue ::Aws::CloudFormation::Errors::ValidationError
      return false
    end

    class CreateError < StandardError
    end

    def update(template, parameters)
      return false unless exists?
      if cf_stack.stack_status == "CREATE_FAILED"
        puts "Stack is in CREATE_FAILED state so must be manually deleted before it can be updated"
        return false
      end
      if cf_stack.stack_status == "ROLLBACK_COMPLETE"
        deleted = delete
        return false if !deleted
      end
      cf_client.update_stack(:stack_name => name, :template_body => template, :parameters => parameters, :capabilities => ["CAPABILITY_IAM"])

      status = wait_for_events
      fail UpdateError, "stack update failed" unless status == "UPDATE_COMPLETE"
      true

    rescue ::Aws::CloudFormation::Errors::ValidationError => e
      if e.message == "No updates are to be performed."
        puts e.message
        return false
      end
      raise e
    end

    class UpdateError < StandardError
    end

    def delete
      return false unless exists?
      cf_client.delete_stack(:stack_name => name)
      status = wait_for_events
      fail UpdateError, "stack delete failed" unless status == "DELETE_COMPLETE"
      true
    rescue Aws::CloudFormation::Errors::ValidationError
      puts "Stack does not exist."
    end

    def deploy(template, parameters = [])
      if exists?
        update(template, parameters)
      else
        create(template, parameters)
      end
    rescue Aws::CloudFormation::Errors::ValidationError => e
      puts e.message
    end

    def outputs
      puts cf_stack.outputs.flat_map { |output| "#{output.output_key} - #{output.output_value}" }
    end

    def valid?(template)
      response = cf_client.validate_template(template)
      response[:code].nil?
    end

    private

    # Wait (displaying stack events) until the stack reaches a stable state.
    #
    def wait_for_events
      loop do
        display_new_events
        cf_stack.reload
        return status if status.nil? || status =~ /_(COMPLETE|FAILED)$/
        sleep(2)
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

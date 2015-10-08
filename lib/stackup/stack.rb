require "aws-sdk-resources"
require "logger"
require "stackup/errors"
require "stackup/stack_watcher"

module Stackup

  # An abstraction of a CloudFormation stack.
  #
  class Stack

    def initialize(name, client = {}, options = {})
      client = Aws::CloudFormation::Client.new(client) if client.is_a?(Hash)
      @name = name
      @cf_client = client
      @watcher = Stackup::StackWatcher.new(cf_stack)
      options.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    attr_reader :name, :cf_client, :watcher

    def on_event(event_handler = nil, &block)
      event_handler ||= block
      fail ArgumentError, "no event_handler provided" if event_handler.nil?
      @event_handler = event_handler
    end

    def status
      cf_stack.stack_status
    rescue Aws::CloudFormation::Errors::ValidationError => e
      handle_validation_error(e)
    end

    def exists?
      status
      true
    rescue NoSuchStack
      false
    end

    ALMOST_DEAD_STATUSES = %w(CREATE_FAILED ROLLBACK_COMPLETE)

    def update(template, parameters)
      status = modify_stack do
        cf_client.update_stack(:stack_name => name, :template_body => template, :parameters => parameters, :capabilities => ["CAPABILITY_IAM"])
      end
      fail StackUpdateError, "stack update failed" unless status == "UPDATE_COMPLETE"
      :updated
    rescue NoUpdateRequired
      nil
    end

    def delete
      return nil unless exists?
      status = modify_stack do
        cf_client.delete_stack(:stack_name => name)
      end
      fail StackUpdateError, "stack delete failed" unless status.nil?
    rescue NoSuchStack
      :deleted
    end

    def deploy(template, parameters = [])
      delete if ALMOST_DEAD_STATUSES.include?(status)
      update(template, parameters)
    rescue NoSuchStack
      create(template, parameters)
    end

    # Returns a Hash of stack outputs.
    #
    def outputs
      {}.tap do |h|
        cf_stack.outputs.each do |output|
          h[output.output_key] = output.output_value
        end
      end
    rescue Aws::CloudFormation::Errors::ValidationError => e
      handle_validation_error(e)
    end

    private

    def create(template, parameters)
      status = modify_stack do
        cf_client.create_stack(
          :stack_name => name,
          :template_body => template,
          :disable_rollback => true,
          :capabilities => ["CAPABILITY_IAM"],
          :parameters => parameters
        )
      end
      fail StackUpdateError, "stack creation failed" unless status == "CREATE_COMPLETE"
      :created
    end

    def logger
      @logger ||= (cf_client.config[:logger] || Logger.new($stdout))
    end

    def cf_stack
      Aws::CloudFormation::Stack.new(:name => name, :client => cf_client)
    end

    def event_handler
      @event_handler ||= lambda do |e|
        fields = [e.logical_resource_id, e.resource_status, e.resource_status_reason]
        logger.info(fields.compact.join(" - "))
      end
    end

    # Execute a block, reporting stack events, until the stack is stable.
    # @return the final stack status
    def modify_stack
      watcher.zero
      yield
      wait_until_stable
    rescue Aws::CloudFormation::Errors::ValidationError => e
      handle_validation_error(e)
    end

    # Wait (displaying stack events) until the stack reaches a stable state.
    # @return the final stack status
    def wait_until_stable
      loop do
        report_new_events
        cf_stack.reload
        return status if status.nil? || status =~ /_(COMPLETE|FAILED)$/
        sleep(5)
      end
    end

    def report_new_events
      watcher.new_events.each do |e|
        event_handler.call(e)
      end
    end

    def handle_validation_error(e)
      case e.message
      when "No updates are to be performed."
        fail NoUpdateRequired, "no updates are required"
      when / does not exist$/
        fail NoSuchStack, "no such stack: #{name}"
      else
        raise e
      end
    end

    # Raised when a stack is already up-to-date
    class NoUpdateRequired < StandardError
    end

  end

end

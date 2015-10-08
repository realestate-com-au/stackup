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
      options.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    attr_reader :name, :cf_client, :watcher

    # Register a handler for reporting of stack events
    # @param [Proc] event_handler
    #
    def on_event(event_handler = nil, &block)
      event_handler ||= block
      fail ArgumentError, "no event_handler provided" if event_handler.nil?
      @event_handler = event_handler
    end

    # @return [String] the current stack status
    # @raise [Stackup::NoSuchStack] if the stack doesn't exist
    #
    def status
      cf_stack.stack_status
    end

    # @return [boolean] true iff the stack exists
    #
    def exists?
      status
      true
    rescue NoSuchStack
      false
    end

    # Create or update the stack.
    #
    # @param [String] template template JSON
    # @param [Array<Hash>] parameters template parameters
    # @return [Symbol] `:created` or `:updated` if successful
    # @raise [Stackup::StackUpdateError] if operation fails
    #
    def create_or_update(template, parameters = [])
      delete if ALMOST_DEAD_STATUSES.include?(status)
      update(template, parameters)
    rescue NoSuchStack
      create(template, parameters)
    end

    alias_method :up, :create_or_update

    ALMOST_DEAD_STATUSES = %w(CREATE_FAILED ROLLBACK_COMPLETE)

    # Delete the stack.
    #
    # @param [String] template template JSON
    # @param [Array<Hash>] parameters template parameters
    # @return [Symbol] `:deleted` if successful
    # @raise [Stackup::StackUpdateError] if operation fails
    #
    def delete
      return nil unless exists?
      status = modify_stack do
        cf_stack.delete
      end
      fail StackUpdateError, "stack delete failed" unless status.nil?
    rescue NoSuchStack
      :deleted
    end

    alias_method :down, :delete

    # Cancel update it progress.
    #
    # @return [Symbol] `:update_cancelled` if successful
    # @raise [Stackup::StackUpdateError] if operation fails
    #
    def cancel_update
      status = modify_stack do
        cf_stack.cancel_update
      end
      fail StackUpdateError, "update cancel failed" unless status =~ /_COMPLETE$/
      :update_cancelled
    rescue InvalidStateError
      nil
    end

    # Get stack outputs.
    #
    # @return [Hash<String, String>]
    #   mapping of logical resource-name to physical resource-name
    # @raise [Stackup::NoSuchStack] if the stack doesn't exist
    #
    def outputs
      {}.tap do |h|
        cf_stack.outputs.each do |output|
          h[output.output_key] = output.output_value
        end
      end
    end

    private

    def create(template, parameters)
      status = modify_stack do
        cf.create_stack(
          :stack_name => name,
          :template_body => template,
          :capabilities => ["CAPABILITY_IAM"],
          :parameters => parameters
        )
      end
      fail StackUpdateError, "stack creation failed" unless status == "CREATE_COMPLETE"
      :created
    rescue Aws::CloudFormation::Errors::ValidationError => e
      Stackup.handle_validation_error(e)
    end

    def update(template, parameters)
      status = modify_stack do
        cf_stack.update(:template_body => template, :parameters => parameters, :capabilities => ["CAPABILITY_IAM"])
      end
      fail StackUpdateError, "stack update failed" unless status == "UPDATE_COMPLETE"
      :updated
    rescue NoUpdateRequired
      nil
    end

    def logger
      @logger ||= (cf_client.config[:logger] || Logger.new($stdout))
    end

    def cf
      Aws::CloudFormation::Resource.new(:client => cf_client)
    end

    def cf_stack
      StackProxy.new(cf.stack(name))
    end

    def event_handler
      @event_handler ||= lambda do |e|
        fields = [e.logical_resource_id, e.resource_status, e.resource_status_reason]
        logger.info(fields.compact.join(" - "))
      end
    end

    # Execute a block, reporting stack events, until the stack is stable.
    #
    # @return the final stack status
    #
    def modify_stack
      watcher = Stackup::StackWatcher.new(cf_stack)
      watcher.zero
      yield
      loop do
        watcher.new_events.each do |e|
          event_handler.call(e)
        end
        cf_stack.reload
        return status if status.nil? || status =~ /_(COMPLETE|FAILED)$/
        sleep(5)
      end
    end

    # Proxy for Aws::CloudFormation::Stack which converts certains
    # types of Aws::CloudFormation::Errors::ValidationError.
    #
    class StackProxy

      def initialize(cf_stack)
        @cf_stack = cf_stack
      end

      def method_missing(*args)
        @cf_stack.public_send(*args)
      rescue Aws::CloudFormation::Errors::ValidationError => e
        Stackup.handle_validation_error(e)
      end

      def respond_to?(method)
        @cf_stack.respond_to?(method)
      end

    end

  end

end

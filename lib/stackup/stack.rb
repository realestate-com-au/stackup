require "aws-sdk-resources"
require "logger"
require "stackup/error_handling"
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

    # Register a handler for reporting of stack events.
    # @param [Proc] event_handler
    #
    def on_event(event_handler = nil, &block)
      event_handler ||= block
      fail ArgumentError, "no event_handler provided" if event_handler.nil?
      @event_handler = event_handler
    end

    include ErrorHandling

    # @return [String] the current stack status
    # @raise [Stackup::NoSuchStack] if the stack doesn't exist
    #
    def status
      handling_validation_error do
        cf_stack.stack_status
      end
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
    # @param [Hash] options create/update options
    #   accepts a superset of the options supported by
    #   +Aws::CloudFormation::Stack#update+
    #   (see http://docs.aws.amazon.com/sdkforruby/api/Aws/CloudFormation/Stack.html#update-instance_method)
    # @return [Symbol] +:created+ or +:updated+ if successful
    # @raise [Stackup::StackUpdateError] if operation fails
    #
    def create_or_update(options)
      options = options.dup
      options[:capabilities] ||= ["CAPABILITY_IAM"]
      delete if ALMOST_DEAD_STATUSES.include?(status)
      update(options)
    rescue NoSuchStack
      create(options)
    end

    alias_method :up, :create_or_update

    ALMOST_DEAD_STATUSES = %w(CREATE_FAILED ROLLBACK_COMPLETE)

    # Delete the stack.
    #
    # @param [String] template template JSON
    # @param [Array<Hash>] parameters template parameters
    # @return [Symbol] +:deleted+ if successful
    # @raise [Stackup::StackUpdateError] if operation fails
    #
    def delete
      begin
        @stack_id = handling_validation_error do
          cf_stack.stack_id
        end
      rescue NoSuchStack
        return nil
      end
      status = modify_stack do
        cf_stack.delete
      end
      fail StackUpdateError, "stack delete failed" unless status == "DELETE_COMPLETE"
      :deleted
    ensure
      @stack_id = nil
    end

    alias_method :down, :delete

    # Cancel update in-progress.
    #
    # @return [Symbol] +:update_cancelled+ if successful
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
    # @return [Hash<String, String>] outputs
    # @raise [Stackup::NoSuchStack] if the stack doesn't exist
    #
    def outputs
      handling_validation_error do
        {}.tap do |h|
          cf_stack.outputs.each do |o|
            h[o.output_key] = o.output_value
          end
        end
      end
    end

    # Get stack outputs.
    #
    # @return [Hash<String, String>]
    #   mapping of logical resource-name to physical resource-name
    # @raise [Stackup::NoSuchStack] if the stack doesn't exist
    #
    def resources
      handling_validation_error do
        {}.tap do |h|
          cf_stack.resource_summaries.each do |r|
            h[r.logical_resource_id] = r.physical_resource_id
          end
        end
      end
    end

    private

    def create(options)
      options[:stack_name] = name
      status = modify_stack do
        cf.create_stack(options)
      end
      fail StackUpdateError, "stack creation failed" unless status == "CREATE_COMPLETE"
      :created
    end

    def update(options)
      options.delete(:disable_rollback)
      status = modify_stack do
        cf_stack.update(options)
      end
      fail StackUpdateError, "stack update failed" unless status == "UPDATE_COMPLETE"
      :updated
    rescue NoUpdateRequired
      nil
    end

    def logger
      @logger ||= cf_client.config[:logger]
      @logger ||= Logger.new($stdout).tap { |l| l.level = Logger::INFO }
    end

    def cf
      Aws::CloudFormation::Resource.new(:client => cf_client)
    end

    def cf_stack
      id_or_name = @stack_id || name
      cf.stack(id_or_name)
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
      handling_validation_error do
        yield
      end
      loop do
        watcher.each_new_event(&event_handler)
        status = self.status
        logger.debug("stack_status=#{status}")
        return status if status.nil? || status =~ /_(COMPLETE|FAILED)$/
        sleep(5)
      end
    end

  end

end

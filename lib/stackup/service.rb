require "aws-sdk-cloudformation"
require "stackup/stack"

module Stackup

  # A handle to CloudFormation.
  #
  class Service

    def initialize(cf_client = {})
      cf_client = Aws::CloudFormation::Client.new(cf_client) if cf_client.is_a?(Hash)
      @cf_client = cf_client
    end

    # @return [Stackup::Stack] the named stack
    #
    def stack(name, options = {})
      Stack.new(name, cf_client, options)
    end

    # @return [Enumeration<String>] names of existing stacks
    #
    def stack_names
      Enumerator.new do |y|
        cf_client.describe_stacks.each do |response|
          response.stacks.each do |stack|
            y << stack.stack_name
          end
        end
      end
    end

    private

    attr_reader :cf_client

  end

end

require "aws-sdk-core"
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

    private

    attr_reader :cf_client

  end

end

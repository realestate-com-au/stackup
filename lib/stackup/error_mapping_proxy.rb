require "stackup/errors"

module Stackup

  # An error-mapping proxy for Aws::CloudFormation models.
  #
  # It exists to convert certain types of `ValidationError`, where useful
  # information is hidden inside the "message", to Stackup exceptions.
  #
  class ErrorMappingProxy

    def initialize(delegate)
      @delegate = delegate
    end

    def method_missing(*args)
      @delegate.send(*args)
    rescue Aws::CloudFormation::Errors::ValidationError => e
      case e.message
      when "No updates are to be performed."
        raise NoUpdateRequired, "no updates are required"
      when /Stack .* does not exist$/
        raise NoSuchStack, "no such stack"
      when / cannot be called from current stack status$/
        raise InvalidStateError, e.message
      else
        raise e
      end
    end

    def respond_to?(method)
      @delegate.respond_to?(method)
    end

  end

end

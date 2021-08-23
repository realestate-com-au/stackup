# frozen_string_literal: true

require "stackup/errors"

module Stackup

  # Handle +Aws::CloudFormation::Errors::ValidationError+.
  #
  module ErrorHandling

    # Invoke an Aws::CloudFormation operation.
    #
    # If an exception is raised, convert it to a Stackup exception,
    # if appropriate.
    #
    def handling_cf_errors
      yield
    rescue Aws::CloudFormation::Errors::ChangeSetNotFound => _e
      raise NoSuchChangeSet, "no such change-set"
    rescue Aws::CloudFormation::Errors::ValidationError => e
      case e.message
      when /Stack .* does not exist/
        raise NoSuchStack, "no such stack"
      when "No updates are to be performed."
        raise NoUpdateRequired, "no updates are required"
      when / can ?not be /
        raise InvalidStateError, e.message
      else
        raise ValidationError, e.message
      end
    end

  end

end

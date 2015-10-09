require "stackup/errors"

module Stackup

  # Handle +Aws::CloudFormation::Errors::ValidationError+.
  #
  module ErrorHandling

    # Invoke an Aws::CloudFormation operation
    #
    # If a +ValidationError+ is raised, check the message; there's often
    # useful information is hidden inside.  If that's the case, convert it to
    # an appropriate Stackup exception.
    #
    def handling_validation_error
      yield
    rescue Aws::CloudFormation::Errors::ValidationError => e
      case e.message
      when "No updates are to be performed."
        raise NoUpdateRequired, "no updates are required"
      when /Stack .* does not exist$/
        raise NoSuchStack, "no such stack"
      when / can ?not be /
        raise InvalidStateError, e.message
      else
        raise ValidationError, e.message
      end
    end

  end

end

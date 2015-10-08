module Stackup

  # Base Stackup Exception class
  class ServiceError < StandardError
  end

  # Raised when the specified stack does not exist
  class NoSuchStack < ServiceError
  end

  # Raised to indicate a problem updating a stack
  class StackUpdateError < ServiceError
  end

  # Raised if we can't perform that operation now
  class InvalidStateError < ServiceError
  end

  # Raised when a stack is already up-to-date
  class NoUpdateRequired < StandardError
  end

  def self.handle_validation_error(e)
    case e.message
    when "No updates are to be performed."
      fail NoUpdateRequired, "no updates are required"
    when /Stack .* does not exist$/
      fail NoSuchStack, "no such stack"
    when / cannot be called from current stack status$/
      fail InvalidStateError, e.message
    else
      raise e
    end
  end

end

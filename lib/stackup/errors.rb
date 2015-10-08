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

end

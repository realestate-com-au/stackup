module Stackup

  # Base Stackup Exception class
  class ServiceError < StandardError; end

  # Raised when something else dodgy happened
  class ValidationError < ServiceError; end

  # Raised when the specified thing does not exist
  class NoSuchThing < ValidationError; end

  # Raised when the specified stack does not exist
  class NoSuchStack < NoSuchThing; end

  # Raised when the specified change-set does not exist
  class NoSuchChangeSet < NoSuchThing; end

  # Raised if we can't perform that operation now
  class InvalidStateError < ValidationError; end

  # Raised when a stack is already up-to-date
  class NoUpdateRequired < ValidationError; end

  # Raised to indicate a problem updating a stack
  class StackUpdateError < ServiceError; end

end

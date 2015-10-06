module Stackup

  class ServiceError < StandardError
  end

  class NoSuchStack < ServiceError
  end

  class StackUpdateError < StandardError
  end

end

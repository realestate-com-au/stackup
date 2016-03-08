module Stackup

  # Parameters to a CloudFormation template.
  #
  class Parameters

    USE_PREVIOUS_VALUE = :use_previous_value

    def initialize(parameter_hash)
      @parameter_hash = parameter_hash
    end

    def to_hash
      @parameter_hash.dup
    end

    def to_a
      @parameter_hash.map do |key, value|
        { :parameter_key => key, :parameter_value => value }
      end
    end

  end

end

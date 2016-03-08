module Stackup

  # Parameters to a CloudFormation template.
  #
  class Parameters

    USE_PREVIOUS_VALUE = :use_previous_value

    class << self

      def new(arg)
        arg = hashify(arg) unless arg.is_a?(Hash)
        super(arg)
      end

      private

      def hashify(parameters)
        {}.tap do |result|
          parameters.each do |p|
            key = p.fetch("ParameterKey") { p.fetch("parameter_key") { p.fetch(:parameter_key) } }
            value = p.fetch("ParameterValue") { p.fetch("parameter_value") { p.fetch(:parameter_value) } }
            result[key] = value
          end
        end
      end

    end

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

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
            p_struct = ParameterStruct.new(p)
            result[p_struct.key] = p_struct.value
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

  class ParameterStruct

    def initialize(attributes)
      attributes.each do |name, value|
        if name.respond_to?(:gsub)
          name = name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
        end
        public_send("#{name}=", value)
      end
    end

    attr_accessor :parameter_key
    attr_accessor :parameter_value
    attr_accessor :use_previous_value

    alias_method :key, :parameter_key
    alias_method :value, :parameter_value

  end

end

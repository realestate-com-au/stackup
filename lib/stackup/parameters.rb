# frozen_string_literal: true

module Stackup

  # Parameters to a CloudFormation template.
  #
  class Parameters

    class << self

      def new(arg)
        arg ||= {}
        arg = hashify(arg) unless arg.is_a?(Hash)
        super(arg)
      end

      private

      def hashify(parameters)
        {}.tap do |result|
          parameters.each do |p|

            p_struct = ParameterStruct.new(p)
            result[p_struct.key] = p_struct.value
          rescue ArgumentError
            raise ArgumentError, "invalid parameter record: #{p.inspect}"

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
        { :parameter_key => key }.tap do |record|
          if value == :use_previous_value
            record[:use_previous_value] = true
          else
            record[:parameter_value] = value.to_s
          end
        end
      end
    end

  end

  class ParameterStruct

    def initialize(attributes)
      attributes.each do |name, value|
        name = name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase if name.respond_to?(:gsub)
        writer = "#{name}="
        raise(ArgumentError, "invalid attribute: #{name.inspect}") unless respond_to?(writer)

        public_send(writer, value)
      end
    end

    attr_accessor :parameter_key
    attr_accessor :parameter_value
    attr_accessor :use_previous_value

    alias key parameter_key

    def value
      if use_previous_value
        :use_previous_value
      else
        parameter_value.to_s
      end
    end

  end

end

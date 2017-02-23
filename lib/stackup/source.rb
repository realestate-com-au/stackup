require "aws-sdk-core"
require "stackup/stack"

module Stackup

  # Represents a source of input, e.g. template, parameter, etc.
  #
  class Source

    def initialize(location)
      @location = location
    end

    attr_reader :location

    def body
      @body ||= IO.read(location)
    rescue Errno::ENOENT
      raise ReadError, "no such file: #{location.inspect}"
    end

    def data
      @data ||= parse_body
    end

    private

    LOOKS_LIKE_JSON = /^\s*[\{\[]/

    def parse_body
      if body =~ LOOKS_LIKE_JSON
        MultiJson.load(body)
      else
        Stackup::YAML.load(body)
      end
    end

    class ReadError < StandardError
    end

  end

end

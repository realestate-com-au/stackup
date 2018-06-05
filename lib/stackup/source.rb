require "aws-sdk-core"
require "open-uri"
require "stackup/stack"

module Stackup

  # Represents a source of input, e.g. template, parameter, etc.
  #
  class Source

    def initialize(location)
      @location = location
    end

    attr_reader :location

    def s3?
      uri.scheme == "https" &&
        uri.host =~ /(^|\.)s3(-\w+-\w+-\d)?\.amazonaws\.com$/
    end

    def body
      @body ||= read
    end

    def data
      @data ||= parse_body
    end

    private

    LOOKS_LIKE_JSON = /\A\s*[\{\[]/

    def uri
      URI(location)
    end

    def read
      if uri.scheme
        uri.read
      else
        IO.read(location)
      end
    rescue Errno::ENOENT
      raise ReadError, "no such file: #{location.inspect}"
    rescue Errno::ECONNREFUSED => e
      raise ReadError, "cannot read #{location.inspect} - #{e.message}"
    rescue OpenURI::HTTPError => e
      raise ReadError, "cannot read #{location.inspect} - #{e.message}"
    rescue SocketError => e
      raise ReadError, "cannot read #{location.inspect} - #{e.message}"
    end

    def parse_body
      if body =~ LOOKS_LIKE_JSON
        # Psych has issues parsing some JSON, so let's use a JSON parser.
        # (see https://github.com/realestate-com-au/stackup/issues/35)
        MultiJson.load(body)
      else
        Stackup::YAML.load(body)
      end
    end

    class ReadError < StandardError
    end

  end

end

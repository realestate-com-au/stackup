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
      uri.host =~ %r{(^|\.)s3(-\w+-\w+-\d)?\.amazonaws\.com$}
    end

    def body
      @body ||= read
    end

    def data
      @data ||= parse_body
    end

    private

    LOOKS_LIKE_JSON = /^\s*[\{\[]/

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
    rescue OpenURI::HTTPError => e
      raise ReadError, "#{e}: #{location.inspect}"
    end

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

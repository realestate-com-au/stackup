require "clamp/option/declaration"
require "multi_json"
require "yaml"

module Stackup

  module DataDisplayOptions

    extend Clamp::Option::Declaration

    option ["-f", "--format"], "FORMAT", "output format", :default => "yaml"

    protected

    def format_data(data)
      case format.downcase
      when "json"
        MultiJson.dump(data, :pretty => true)
      when "yaml"
        YAML.dump(data)
      end
    end

    def display_data(data)
      puts format_data(data)
    end

  end

end

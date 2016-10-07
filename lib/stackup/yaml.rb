require "yaml"

module Stackup

  # Modified YAML parsing, to support CloudFormation YAML shortcuts
  #
  module YAML

    class << self

      # Dump Ruby object +o+ to a YAML string.
      #
      def dump(*args)
        ::YAML.dump(*args)
      end

      # Load YAML stream/string into a Ruby data structure.
      #
      # Supports CloudFormation extensions:
      #
      #   `!Ref blah` as a shortcut for `{ "Ref" => blah }`
      #   `!Foo blah` as a shortcut for `{ "Fn::Foo" => blah }`
      #
      def load(yaml, filename = nil)
        tree = ::YAML.parse(yaml, filename)
        return tree unless tree
        CloudFormationToRuby.create.accept(tree)
      end

      # Load YAML file into a Ruby data structure.
      #
      # Supports CloudFormation extensions as per `load`.
      #
      def load_file(filename)
        File.open(filename, 'r:bom|utf-8') do |f|
          load(f, filename)
        end
      end

    end

    # Custom Psych node visitor, with CloudFormation extensions.
    #
    class CloudFormationToRuby < Psych::Visitors::ToRuby

      def accept(target)
        case target.tag
        when "!Ref"
          { "Ref" => super }
        when /^!(\w+)$/
          { "Fn::#{$1}" => super }
        else
          super
        end
      end

    end

  end

end

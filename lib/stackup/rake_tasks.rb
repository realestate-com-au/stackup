require "rake/tasklib"
require "tempfile"
require "yaml"
require "Pathname"

module Stackup

  # Declare Rake tasks for managing a stack.
  #
  class RakeTasks < Rake::TaskLib

    attr_accessor :name
    attr_accessor :stack
    attr_accessor :template
    attr_accessor :parameters
    attr_accessor :tags
    attr_accessor :capabilities

    alias namespace= name=

    def initialize(name, template = nil)
      @name = name
      @stack = name
      @template = template
      yield self if block_given?
      raise ArgumentError, "no name provided" unless @name
      raise ArgumentError, "no template provided" unless @template

      define
    end

    # path to the "stackup" executable
    STACKUP_CLI = File.expand_path("../../bin/stackup", __dir__)

    def stackup(*rest)
      sh STACKUP_CLI, "-Y", stack, *rest
    end

    def define
      namespace(name) do

        data_options = []
        data_options += DataOption.for("--template", template).to_a
        data_options += DataOption.for("--parameters", parameters).to_a if parameters
        data_options += DataOption.for("--tags", tags).to_a if tags
        data_options += DataOption.for("--capability", capabilities).to_a if capabilities

        desc "Update #{stack} stack"
        task "up" => data_options.grep(DataOptionFile) do
          stackup "up", *data_options
        end

        desc "Cancel update of #{stack} stack"
        task "cancel" do
          stackup "cancel-update"
        end

        desc "Show pending changes to #{stack} stack"
        task "diff" => data_options.grep(DataOptionFile) do
          stackup "diff", *data_options
        end

        desc "Show #{stack} stack outputs and resources"
        task "inspect" do
          stackup "inspect"
        end

        desc "Show #{stack} stack outputs only"
        task "outputs" do
          stackup "outputs"
        end

        desc "Delete #{stack} stack"
        task "down" do
          stackup "down"
        end

      end
    end

    # A flag with optional argument that will be passed to stackup
    class DataOption

      def initialize(flag, argument)
        @flag = flag
        @argument = argument if argument
      end

      def to_a
        [@flag, @argument]
      end

      # Factory method for initialising DataOptions based on class
      def self.for(flag, argument)
        case argument
        when Hash
          DataOptionHash.new(flag, argument)
        when Array
          DataOptionArray.new(flag, argument)
        when String && File.exist?(argument)
          DataOptionFile.new(flag, argument)
        else
          DataOption.new(flag, argument)
        end
      end

    end

    # An option with a Hash argument
    # Hash content is stored in a temporary file upon conversion
    class DataOptionHash < DataOption

      def as_tempfile(filename, data)
        tempfile = Tempfile.new(filename)
        tempfile.write(YAML.dump(data))
        tempfile.close
        tempfile.path.to_s
      end

      def to_a
        [@flag, as_tempfile([@flag[2..-1], ".yml"], @argument)]
      end

    end

    # An option with an Array argument
    # Flag is repeated for every Array member upon conversion
    class DataOptionArray < DataOption

      def to_a
        [].tap do |result|
          @argument.each do |argument|
            result << @flag
            result << argument
          end
        end
      end

    end

    # An option with a File argument
    class DataOptionFile < DataOption; end

  end

end

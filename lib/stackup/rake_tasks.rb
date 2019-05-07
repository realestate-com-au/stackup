require "rake/tasklib"
require "tempfile"
require "yaml"

module Stackup

  # Declare Rake tasks for managing a stack.
  #
  class RakeTasks < Rake::TaskLib

    attr_accessor :name
    attr_accessor :stack
    attr_accessor :template
    attr_accessor :parameters
    attr_accessor :tags

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

        data_options = DataOptions.new
        data_options["--template"] = template
        data_options["--parameters"] = parameters if parameters
        data_options["--tags"] = tags if tags

        desc "Update #{stack} stack"
        task "up" => data_options.files do
          stackup "up", *data_options.to_a
        end

        desc "Cancel update of #{stack} stack"
        task "cancel" do
          stackup "cancel-update"
        end

        desc "Show pending changes to #{stack} stack"
        task "diff" => data_options.files do
          stackup "diff", *data_options.to_a
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

    # Options to "stackup up".
    #
    class DataOptions

      def initialize
        @options = {}
      end

      def []=(option, file_or_value)
        @options[option] = file_or_value
      end

      def files
        @options.values.grep(String)
      end

      def to_a
        [].tap do |result|
          @options.each do |option, file_or_data|
            result << option
            result << maybe_tempfile(file_or_data, option[2..-1])
          end
        end
      end

      def maybe_tempfile(file_or_data, type)
        return file_or_data if file_or_data.is_a?(String)

        tempfile = Tempfile.new([type, ".yml"])
        tempfile.write(YAML.dump(file_or_data))
        tempfile.close
        tempfile.path.to_s
      end

    end

  end

end

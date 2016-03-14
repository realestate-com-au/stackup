require "rake/tasklib"

module Stackup

  # Declare Rake tasks for managing a stack.
  #
  class RakeTasks < Rake::TaskLib

    attr_accessor :name
    attr_accessor :stack
    attr_accessor :template
    attr_accessor :parameters
    attr_accessor :tags

    alias_method :namespace=, :name=

    def initialize(name, template = nil)
      @name = name
      @stack = name
      @template = template
      yield self if block_given?
      fail ArgumentError, "no name provided" unless @name
      fail ArgumentError, "no template provided" unless @template
      define
    end

    # path to the "stackup" executable
    STACKUP_CLI = File.expand_path("../../../bin/stackup", __FILE__)

    def stackup(*rest)
      sh STACKUP_CLI, "-Y", stack, *rest
    end

    def define
      namespace(name) do

        up_args = {}
        up_args["--template"] = template
        up_args["--parameters"] = parameters if parameters
        up_args["--tags"] = tags if tags

        desc "Update #{stack} stack"
        task "up" => up_args.values do
          stackup "up", *up_args.to_a.flatten
        end

        desc "Cancel update of #{stack} stack"
        task "cancel" do
          stackup "cancel-update"
        end

        desc "Show pending changes to #{stack} stack"
        task "diff" => up_args.values do
          stackup "diff", *up_args.to_a.flatten
        end

        desc "Show #{stack} stack outputs and resources"
        task "inspect" do
          stackup "inspect"
        end

        desc "Delete #{stack} stack"
        task "down" do
          stackup "down"
        end

      end
    end

  end

end

require "rake/tasklib"

module Stackup

  # Declare Rake tasks for managing a stack.
  #
  class RakeTasks < Rake::TaskLib

    attr_accessor :name
    attr_accessor :stack
    attr_accessor :template
    attr_accessor :parameters

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

    def define
      namespace(name) do

        template_and_params = "-t #{template}"
        template_and_params += " -p #{parameters}" if parameters

        desc "Update #{stack} stack"
        task "up" => template do
          sh "stackup #{stack} up #{template_and_params}"
        end

        desc "Show pending changes to #{stack} stack"
        task "diff" => template do
          sh "stackup #{stack} diff #{template_and_params}"
        end

        desc "Show #{stack} stack outputs and resources"
        task "inspect" do
          sh "stackup #{stack} inspect -Y"
        end

        desc "Delete #{stack} stack"
        task "down" do
          sh "stackup #{stack} down"
        end

      end
    end

  end

end

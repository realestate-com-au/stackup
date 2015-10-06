require "clamp"
require "console_logger"
require "stackup/data_display_options"
require "stackup/stack"

module Stackup

  class CLI < Clamp::Command

    include DataDisplayOptions

    option "--debug", :flag, "enable debugging"

    protected

    def logger
      @logger ||= ConsoleLogger.new($stdout, debug?)
    end

    subcommand "stack", "Manage a stack." do

      parameter "NAME", "Name of stack", :attribute_name => :stack_name

      def run(*args)
        super(*args)
      rescue Stackup::NoSuchStack => e
        signal_error "stack '#{stack_name}' does not exist"
      end

      private

      def stack
        Stackup::Stack.new(stack_name, :logger => logger, :log_level => :debug)
      end

      subcommand "status", "Print stack status." do

        def execute
          puts stack.status
        end

      end

      subcommand "deploy", "Create/update the stack" do

        parameter "TEMPLATE", "CloudFormation template (.json)", :attribute_name => :template_file

        def execute
          template = File.read(template_file)
          stack.deploy(template)
        end

      end

      subcommand "delete", "Remove the stack." do

        def execute
          stack.delete
        rescue Stackup::NoSuchStack
          # that's okay
        end

      end

      subcommand "outputs", "Stack outputs." do

        def execute
          display_data(stack.outputs)
        end

      end

    end

  end

end

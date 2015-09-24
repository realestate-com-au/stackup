module Stackup
  class CLI < Clamp::Command

    subcommand ["stack"], "Manage a stack." do
      parameter "STACK-NAME", "Name of stack", :attribute_name => :stack_name

      subcommand "deploy", "Create/update the stack" do
        parameter "TEMPLATE", "CloudFormation template (.json)", :attribute_name => :template
        parameter "PARAMETERS", "CloudFormation parameters (.json)", :attribute_name => :parameters

        def execute
          params = JSON.parse(parameters)
          stack = Stackup::Stack.new(stack_name)
          stack.create(template, params)
        end
      end

      subcommand "delete", "Remove the stack." do
        def execute
          stack = Stackup::Stack.new(stack_name)
          stack.delete
        end
      end

      subcommand "outputs", "Stack outputs." do
        def execute
          stack = Stackup::Stack.new(stack_name)
          stack.outputs
        end
      end
    end

  end
end

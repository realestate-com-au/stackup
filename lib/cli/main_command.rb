module Stackup
  class CLI < Clamp::Command

    subcommand ["stack"], "Manage a stack." do
      parameter "STACK-NAME", "Name of stack", :attribute_name => :stack_name

      subcommand "apply", "Create/update the stack" do
        parameter "TEMPLATE", "CloudFormation template (.json)", :attribute_name => :template

        def execute
          stack = Stackup::Stack.new(stack_name, template)
          stack.create
        end
      end
    end

  end
end

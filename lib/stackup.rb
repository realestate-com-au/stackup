require "forwardable"
require "stackup/service"
require "stackup/stack"

# Allow use of `Stackup.stacks` rather than `Stackup().stacks`
#
module Stackup

  class << self

    def service(client = {})
      Stackup::Service.new(client)
    end

    extend Forwardable

    def_delegators :service, :stack, :stack_names

  end

end

# rubocop:disable Naming/MethodName

def Stackup(*args)
  Stackup.service(*args)
end

# rubocop:enable Naming/MethodName

require "stackup/service"
require "stackup/stack"

def Stackup(client = {})
  Stackup::Service.new(client)
end

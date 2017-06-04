require "byebug"
require "console_logger"

module CfStubbing

  def stub_cf_client
    client_options = { :stub_responses => true }
    client_options[:logger] = Logger.new(nil)
    if ENV.key?("AWS_DEBUG")
      client_options[:logger] = ConsoleLogger.new(STDOUT, true)
      client_options[:log_level] = :debug
    end
    Aws::CloudFormation::Client.new(client_options)
  end

end

RSpec.configure do |c|
  c.mock_with :rspec
  c.include CfStubbing
end

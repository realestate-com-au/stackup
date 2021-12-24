# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "stackup/version"

Gem::Specification.new do |spec|

  spec.name          = "stackup"
  spec.version       = Stackup::VERSION
  spec.authors       = ["Danial Pearce", "Ahmed Shash"]
  spec.email         = ["danial.pearce@rea-group.com", "ahmed.shash@rea-group.com"]
  spec.summary       = "Manage CloudFormation stacks"
  spec.homepage      = "https://github.com/realestate-com-au/stackup"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib,spec}/**/*") + %w[README.md CHANGES.md LICENSE.md]
  spec.test_files    = spec.files.grep(/^spec/)

  spec.require_paths = ["lib"]

  spec.bindir = "bin"
  spec.executables << "stackup"

  spec.add_dependency "aws-sdk-cloudformation", "~> 1.6"
  spec.add_dependency "clamp", "~> 1.2"
  spec.add_dependency "console_logger"
  spec.add_dependency "diffy", "~> 3.2"
  spec.add_dependency "multi_json"

  spec.required_ruby_version = "> 2.6"
end

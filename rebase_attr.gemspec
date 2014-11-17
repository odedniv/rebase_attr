# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rebase_attr/version'

Gem::Specification.new do |spec|
  spec.name          = "rebase_attr"
  spec.version       = RebaseAttr::VERSION
  spec.authors       = ["Oded Niv"]
  spec.email         = ["oded.niv@gmail.com"]
  spec.summary       = %q{Convert an attribute to a specified base.}
  spec.description   = %q{Override attribute readers and writers with base encoders.}
  spec.homepage      = "https://github.com/odedniv/rebase_attr"
  spec.license       = "UNLICENSE"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "generate_method", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rspec-its", "~> 1.0"
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cumuliform/version'

Gem::Specification.new do |spec|
  spec.name          = "cumuliform"
  spec.version       = Cumuliform::VERSION
  spec.authors       = ["Matt Patterson"]
  spec.email         = ["matt@reprocessed.org"]

  spec.summary       = %q{DSL library for generating AWS CloudFormation templates}
  spec.description   = <<-EOD
Simple DSL for generating AWS CloudFormation templates with an emphasis
on ensuring you don't shoot yourself in the foot by, e.g. referencing
non-existent resources because you have a typo.
  EOD
  spec.homepage      = "https://www.github.com/tape-tv/cumuliform"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "yard", ">= 0.8"
  spec.add_development_dependency "simplecov"
end

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "stax/stacksets/version"

Gem::Specification.new do |spec|
  spec.name          = "stax-stacksets"
  spec.version       = Stax::Stacksets::VERSION
  spec.authors       = ['Richard Lister']
  spec.email         = ["rlister@gmail.com"]

  spec.summary       = %q{Add Cloudformation StackSets support to stax.}
  spec.description   = %q{Allows stax to create a StackSet for each stack in a project.}
  spec.homepage      = 'https://github.com/rlister/stax-stacksets'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "docile", "~> 1.2.0"

  spec.add_dependency('stax')
end
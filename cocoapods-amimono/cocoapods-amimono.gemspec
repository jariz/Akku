# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-amimono/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-amimono'
  spec.version       = CocoapodsAmimono::VERSION
  spec.authors       = ['Renzo Crisostomo']
  spec.email         = ['renzo.crisostomo@me.com']
  spec.description   = %q{Move all dynamic frameworks symbols into the main executable.}
  spec.summary       = %q{Move all dynamic frameworks symbols into the main executable.}
  spec.homepage      = 'https://github.com/Ruenzuo/cocoapods-amimono'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.rubygems_version = "1.6.2"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=
  spec.required_ruby_version = '>= 2.0.0'
  spec.specification_version = 3 if spec.respond_to? :specification_version
end

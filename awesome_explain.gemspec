# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awesome_explain/version'

Gem::Specification.new do |spec|
  spec.name          = 'awesome_explain'
  spec.version       = AwesomeExplain::VERSION
  spec.authors       = ['Ahmed El.Hussaini']
  spec.email         = ['aelhussaini@gmail.com']

  spec.summary       = 'Awesome and simple approach to explain Mongoid queries'
  spec.description   = 'An awesome and simple approach to explain Mongoid queries that provides winning plan stages and overall statistics'
  spec.homepage      = 'https://github.com/sandboxws/awesome_explain'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'awesome_print', '~> 1.0'
  spec.add_dependency 'terminal-table', '~> 1.0'
  spec.add_dependency 'sqlite3', '~> 1.4.2'
  spec.add_dependency 'rails', '>= 5.0'
  spec.add_dependency 'kaminari', '>= 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'puma'
  spec.add_development_dependency 'binding_of_caller'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-rails'
  spec.add_development_dependency 'mongoid', '>= 5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
  spec.add_development_dependency 'simplecov-console', '~> 0.4.2'
end

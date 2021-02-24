# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twine-rails/version'

Gem::Specification.new do |spec|
  spec.name          = "twine-rails"
  spec.version       = TwineRails::VERSION
  spec.authors       = ["Justin Li", "Kristian Plettenberg-Dussault", "Anthony Cameron"]
  spec.email         = ["jli@shopify.com"]
  spec.summary       = "Minimalistic two-way bindings"
  spec.homepage      = "https://github.com/Shopify/twine"
  spec.license       = "MIT"
  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/Shopify/twine/issues',
    'changelog_uri' => 'https://github.com/Shopify/twine/releases',
    'source_code_uri' => 'https://github.com/Shopify/twine',
    'allowed_push_host' => 'https://rubygems.org'
  }

  spec.add_dependency "coffee-rails"
  spec.add_dependency "railties"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end

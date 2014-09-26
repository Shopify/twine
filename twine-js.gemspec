# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "twine-js"
  spec.version       = "0.0.4"
  spec.authors       = ["Justin Li", "Kristian Plettenberg-Dussault", "Anthony Cameron"]
  spec.email         = ["jli@shopify.com"]
  spec.summary       = "Minimalistic two-way bindings"
  spec.homepage      = "https://github.com/Shopify/twine"
  spec.license       = "MIT"
  spec.files         = Dir["lib/assets/javascripts/*.js.coffee", "README.md", "LICENSE"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end

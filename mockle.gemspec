# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'mockle'
  spec.version       = '0.1.alpha1'
  spec.authors       = ['Magnus Holm']
  spec.email         = ['judofyr@gmail.com']
  spec.description   = %q{A Ruby parser.}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/judofyr/mockle.rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/) + %w(lib/mockle/parser.rb)
  spec.executables   = %w()
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9'

  spec.add_dependency             'ast',       '~> 1.0'

  spec.add_development_dependency 'bundler',   '~> 1.2'
  spec.add_development_dependency 'rake',      '~> 0.9'
  spec.add_development_dependency 'racc'

  spec.add_development_dependency 'minitest',  '~> 4.7.0'
  spec.add_development_dependency 'simplecov'
end


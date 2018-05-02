lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'n1ql/version'

Gem::Specification.new do |spec|
  spec.name          = 'n1ql'
  spec.version       = N1ql::VERSION
  spec.authors       = ['Artem Chistyakov']
  spec.email         = ['chistyakov.artem@gmail.com']

  spec.summary       = %q{N1QL parser and compiler to CouchBase Lite Core JSON}
  spec.homepage      = 'https://github.com/temochka/n1ql'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_dependency 'parslet', '~> 1.8'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.11'
end

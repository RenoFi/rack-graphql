lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack_graphql/version'

Gem::Specification.new do |spec|
  spec.name = 'rack-graphql'
  spec.version = RackGraphql::VERSION
  spec.authors = ['Krzysztof Knapik', 'RenoFi Engineering Team']
  spec.email = ['knapo@knapo.net', 'engineering@renofi.com']

  spec.summary = 'Rack middleware implementing graphql endpoint.'
  spec.homepage = 'https://github.com/RenoFi/rack-graphql'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = 'https://github.com/RenoFi/rack-graphql'
  spec.metadata['source_code_uri'] = 'https://github.com/RenoFi/rack-graphql'
  spec.metadata['changelog_uri'] = 'https://github.com/RenoFi/rack-graphql/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(bin/|spec/|\.rub)}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'graphql', '~> 2.0'
  spec.add_dependency 'oj'
  spec.add_dependency 'rack', '~> 2.2'

  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
end

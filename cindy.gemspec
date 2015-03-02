# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cindy/version'

Gem::Specification.new do |s|
    s.name = 'cindy-cm'
    s.version = Cindy::VERSION
    s.authors = ['julp']
    s.summary = 'Turn out your configuration files into ERB templates and deploy them'
    s.homepage = 'https://github.com/julp/cindy'
    s.license = 'BSD'
    s.files = `git ls-files -z`.split("\x0")
    s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
    #s.require_paths = %w(lib)
    s.required_ruby_version = '>= 2.0.0'
    s.add_dependency 'net-ssh'
    s.add_dependency 'highline'
    s.add_development_dependency 'bundler'
    s.add_development_dependency 'rake'
end

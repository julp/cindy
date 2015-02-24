require './lib/cindy/version'

Gem::Specification.new do |s|
    s.name = 'cindy'
    s.version = Cindy.version
    s.authors = %w[julp]
    s.summary = ''
    s.description = ''
    s.homepage = ''
    s.files = ''
    s.executables = %w[cindy]
    s.license = 'BSD'
    s.required_ruby_version = '>= 1.9.3'
    s.add_dependency 'net-scp'
end
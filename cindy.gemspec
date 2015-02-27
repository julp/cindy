require './lib/cindy/version'

Gem::Specification.new do |s|
    s.name = 'cindy'
    s.version = Cindy.version
    s.authors = %w[julp]
    s.summary = 'Turn out your configuration files into ERB templates and deploy them'
    s.description = ''
    s.homepage = 'https://github.com/julp/cindy'
    s.files = ''
    s.executables = %w[cindy]
    s.license = 'BSD'
    s.required_ruby_version = '>= 2.0.0'
    s.add_dependency 'net-ssh'
end

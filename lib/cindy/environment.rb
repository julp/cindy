require 'rexml/document'

module Cindy
    class Environment
        TAG_NAME = self.name.split('::').last.downcase

        attr_reader :name, :uri

        def initialize(name, uri)
            @uri = uri
            @name = name
        end

        def to_xml(parent)
            parent << envtag = REXML::Element.new(TAG_NAME)
            envtag.attributes['name'] = self.name
            envtag.attributes['uri'] = self.uri
        end

        class << self
            def from_xml(environments, root)
                root.elements.each(TAG_NAME) do |env|
                    environments[env.attributes['name']] = Environment.new(env.attributes['name'], env.attributes['uri'])
                end
            end
        end
    end
end

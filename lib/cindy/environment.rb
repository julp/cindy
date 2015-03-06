module Cindy
    class Environment

        attr_reader :name, :uri

        def initialize(name, uri)
            @uri = uri
            @name = name
        end

#         def to_xml(parent)
#             parent << envtag = REXML::Element.new(TAG_NAME)
#             envtag.attributes['name'] = self.name
#             envtag.attributes['uri'] = self.uri
#         end

        def to_s
            "environment :#{@name}, #{@uri.inspect}"
        end

        def update(attributes)
            @uri = attributes['uri'] if attributes['uri']
            @name = attributes['name'] if attributes['name']
        end
    end
end

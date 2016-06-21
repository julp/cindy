module Cindy
    class TplEnv < Scope

        attr_reader :path

        def initialize(tpl, path)
            @tpl = tpl
            super @tpl
            @path = path # remote filename to deploy as
        end

    end
end

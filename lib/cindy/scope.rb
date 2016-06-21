module Cindy
    class Scope

        def initialize(parent = nil)
            @parent = parent
            @variables = {}
        end

        def get_variable(name)
            self[name.intern]
        end

        def set_variable(name, value)
            STDERR.puts "[ WARN ] non standard variable name found" unless name =~ /\A[a-z][a-z0-9_]*\z/
            @variables[name.intern] = value
        end

        def scope(executor)
            scopes = []
            variables = {}
            parent = self
            while parent
                scopes << parent
                parent = parent.parent
            end
            scopes.reverse.each do |s|
                variables.merge!(s.variables)
            end
            variables.map do |k, v|
                if v.respond_to? :call
                    [ k, v.call(executor) ]
                else
                    [ k, v ]
                end
            end
            variables
        end

protected

        def parent
            @parent
        end

        def variables
            @variables
        end

        def [](name)
            value = @variables[name]
            while value.nil? && !@parent.nil?
                value = @parent[name]
            end
            value
        end

    end
end

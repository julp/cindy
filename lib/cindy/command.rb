module Cindy
    class Command
        def initialize(command, options = {})
            @command = command
            @options = options
        end

        def to_s
            @command
        end

        def inspect
            "#{self.class.name}.new(#{@command.inspect}, TODO)"
        end

        def call(executor)
            executor.exec(@command, @options)
        end
    end
end

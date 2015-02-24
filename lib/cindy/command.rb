module Cindy
    class Command
        def initialize(command)
            @command = command
        end

        def to_s
            @command
        end

        def call(executor)
            executor.exec(@command, nil, true)
        end
    end
end

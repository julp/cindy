module Cindy
    class Variable
        TAG_NAME = self.name.split('::').last.downcase

        class << self
            def parse_boolean(string)
                'true' == string
            end

            def parse_string(string)
                string
            end

            def parse_command(string)
                Command.new string
            end

            def parse_int(string)
                string.to_i
            end
        end

        TYPES = public_methods.inject([]) do |ret,v|
            ret << $' if v =~ /\Aparse_/
            ret
        end
    end
end

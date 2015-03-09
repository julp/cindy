module Cindy
    class CLI
        ARGS_ALIASES = Hash.new do |h,k|
            k
        end.merge!({ 'tpl' => 'template', 'var' => 'variable', 'env' => 'environment' })

        class InvalidArgumentError < ::ArgumentError
            def initialize(given, expected)
                super "invalid argument '#{given}'" + case expected
                    when String
                        ", expecting '#{expected}'"
                    when Array
                        ", expecting one of: '#{expected.join('\', \'')}'"
                end
            end
        end

#         class TooManyArgumentError < ::ArgumentError
#             def initialize
#                 super "too many arguments"
#             end
#         end
# 
#         class TooFewArgumentError < ::ArgumentError
#             def initialize
#                 super "too few arguments"
#             end
#         end

        def initialize
            @cindy = Cindy.load ENV['CINDY_CONF']
        end

        def environments
            @cindy.environments.map { |v| v.name.to_s }
        end

        def templates
            @cindy.templates.map { |v| v.alias.to_s }
        end

#         def check_args_count(given, expected, method = :"==")
#             raise (given > expected ? TooManyArgumentError : TooFewArgumentError).new unless given.send(method, expected)
#         end

        def parse(args)
            arg = args.shift
            case ARGS_ALIASES[arg]
            when 'reload'
                # assert 0 == args.length
                @cindy = Cindy.load ENV['CINDY_CONF']
            when 'environment'
                arg = args.shift
                case arg
                when 'list'
                    # assert 0 == args.length
                    @cindy.environments.each do |env|
                        puts "- #{env.name}: #{env.uri}"
                    end
                end
            when 'template'
                arg = args.shift
                case arg
                when 'list'
                    # assert 0 == args.length
                    @cindy.templates.each do |tpl|
                        puts "> #{tpl.alias}: #{tpl.file}"
                    end
                else
                    tplname = arg
                    arg = args.shift
                    case ARGS_ALIASES[arg]
                    when 'environment'
                        # assert args.length >= 2
                        envname = args.shift
                        arg = args.shift
                        case ARGS_ALIASES[arg]
                        when 'details'
                            # assert 0 == args.length
                            @cindy.template_environment_variables(envname, tplname)
                        when 'deploy', 'print'
                            # assert 0 == args.length
                            @cindy.send(:"template_environment_#{arg}", envname, tplname)
                        else
                            raise InvalidArgumentError.new arg, %w(details deploy print)
                        end
                    else
                        raise InvalidArgumentError.new arg, %w(environment)
                    end
                end
            else
                raise InvalidArgumentError.new arg, %w(reload environment template)
            end
        end
    end
end

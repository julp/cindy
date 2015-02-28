# @dev
module Kernel
    def debug *args
        self.send(:printf, *args) if $VERBOSE # ajouter -v à la ligne de commande pour passer en verbose
    end
end

module Cindy
    class CLI
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
            @cindy = Cindy.new
        end

#         def check_args_count(given, expected, method = :"==")
#             raise (given > expected ? TooManyArgumentError : TooFewArgumentError).new unless given.send(method, expected)
#         end

        def parse(args)
            arg = args.shift
            case arg
            when 'environment', 'env'
                arg = args.shift
                case
                when 'list' == arg
                    # assert 0 == args.length
                    @cindy.environments.each do |env|
                        puts "- #{env.name}: #{env.uri}"
                    end
                when %w(create update).include?(arg) # TODO
                    # assert(2 == args.length)
                    @cindy.send(:"environment_#{arg}", *args)
                else
                    # assert args.length >= 2
                    envname = arg
                    arg = args.shift
                    case
                    when 'delete' == arg
                        # assert 0 == args.length
                        @cindy.environment_delete envname
                    else
                        raise InvalidArgumentError.new arg, %w(delete)
                    end
                end
            when 'template', 'tpl'
                arg = args.shift
                case arg
                when 'list'
                    # assert 0 == args.length
                    @cindy.templates.each do |tpl|
                        puts "> #{tpl.alias || '(none)'}: #{tpl.file}"
                    end
                when 'add'
                    # assert 3 == args.length
                    raise InvalidArgumentError.new args[1], 'as' unless 'as' == args[1]
                    @cindy.template_add args[0], args[2]
                else
                    tplname = arg
                    arg = args.shift
                    case arg
                    when 'delete'
                        # assert 0 == args.length
                        @cindy.template_delete tplname
                    when 'variable', 'var'
                        # assert args.length >= 2
                        varname = args.shift
                        arg = args.shift
                        case arg
                        when 'unset'
                            # assert 0 == args.length
                            @cindy.template_variable_unset tplname, varname
                        when 'set', '='
                            # assert args.length >= 1 && args.length <= 3
                            raise InvalidArgumentError.new args[1], 'typed' if args.length > 1 && 'typed' != args[1]
                            @cindy.template_variable_set tplname, varname, args[0], args[2]
                        else
                            raise InvalidArgumentError.new arg, %w(unset)
                        end
                    when 'environment', 'env'
                        # assert args.length >= 2
                        envname = args.shift
                        arg = args.shift
                        case arg
                        when 'variable', 'var'
                            # assert args.length >= 1
                            arg = args.shift
                            case arg
                            when 'list'
                                # assert 0 == args.length
                                @cindy.template_environment_variables(envname, tplname)
                            else
                                varname = arg
                                arg = args.shift
                                case arg
                                when 'set', '='
                                    # assert args.length >= 1 && args.length <= 3
                                    raise InvalidArgumentError.new args[1], 'typed' if args.length > 1 && 'typed' != args[1]
                                    @cindy.template_environment_variable_set envname, tplname, varname, args[0], args[2]
                                else
                                    raise InvalidArgumentError.new arg, %w(list set)
                                end
                            end
                        when 'path'
                            # assert 2 == args.length
                            raise InvalidArgumentError.new args[0], '=' unless '=' == args[0]
                            @cindy.template_environment_path envname, tplname, args[1]
                        when 'deploy', 'print'
                            # assert 0 == args.length
                            @cindy.send(:"template_environment_#{arg}", envname, tplname)
                        else
                            raise InvalidArgumentError.new arg, %w(variable deploy print)
                        end
                    else
                        raise InvalidArgumentError.new arg, %w(environment delete variable environment)
                    end
                end
            else
                raise InvalidArgumentError.new arg, %w(environment template)
            end
        end
    end
end

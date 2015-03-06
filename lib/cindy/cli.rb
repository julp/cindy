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
            @cindy = Cindy.load ENV['CINDY_CONF']
        end

        def finalize!
            @cindy.save!
        end

#         def check_args_count(given, expected, method = :"==")
#             raise (given > expected ? TooManyArgumentError : TooFewArgumentError).new unless given.send(method, expected)
#         end

        TEMPLATE_UPDATE_ARGS = %w(name file)
        ENVIRONMENT_UPDATE_ARGS = %w(name uri)

        def parse(args)
            arg = args.shift
            case arg
            when 'environment', 'env'
                arg = args.shift
                case arg
                when 'list'
                    # assert 0 == args.length
                    @cindy.environments.each do |env|
                        puts "- #{env.name}: #{env.uri}"
                    end
                when 'create'
                    # assert 2 == args.length
                    raise InvalidArgumentError.new args[1], 'as' unless 'as' == args[1]
                    @cindy.environment_create args[2], args[0]
                else
                    # assert args.length >= 2
                    envname = arg
                    arg = args.shift
                    case
                    when 'delete' == arg
                        # assert 0 == args.length
                        @cindy.environment_delete envname
                    when 'update'
                        # assert args.length >= 3 && 0 == args.length % 3
                        params = args.each_slice(3).inject({}) do |ret,a|
                            raise InvalidArgumentError.new a[0], ENVIRONMENT_UPDATE_ARGS unless ENVIRONMENT_UPDATE_ARGS.include? a[0]
                            raise InvalidArgumentError.new a[1], '=' unless '=' == a[1]
                            ret.update a[0] => a[2]
                        end
                        @cindy.environment_update envname, params
                    else
                        raise InvalidArgumentError.new arg, %w(delete update)
                    end
                end
            when 'template', 'tpl'
                arg = args.shift
                case arg
                when 'list'
                    # assert 0 == args.length
                    @cindy.templates.each do |tpl|
                        puts "> #{tpl.alias}: #{tpl.file}"
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
                    when 'update'
                        # assert args.length >= 3 && 0 == args.length % 3
                        params = args.each_slice(3).inject({}) do |ret,a|
                            raise InvalidArgumentError.new a[0], TEMPLATE_UPDATE_ARGS unless TEMPLATE_UPDATE_ARGS.include? a[0]
                            raise InvalidArgumentError.new a[1], '=' unless '=' == a[1]
                            ret.update a[0] => a[2]
                        end
                        @cindy.template_update tplname, params
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
                        when 'rename'
                            # assert 2 == args.length
                            raise InvalidArgumentError.new args[0], 'to' unless 'to' == args[0]
                            @cindy.template_variable_rename tplname, varname, args[1]
                        else
                            raise InvalidArgumentError.new arg, %w(unset set rename)
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
                        raise InvalidArgumentError.new arg, %w(environment delete update variable environment)
                    end
                end
            else
                raise InvalidArgumentError.new arg, %w(environment template)
            end
        end
    end
end

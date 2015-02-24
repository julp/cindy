require 'rexml/document'

# @dev
module Kernel
    def debug *args
        self.send(:printf, *args) if $VERBOSE # ajouter -v à la ligne de commande pour passer en verbose
    end
end

module Cindy
    class CLI
        class UnexpectedArgumentError < ::ArgumentError
        end

        def initialize
            @cindy = Cindy.new
        end

        def parse(args)
            arg = args.shift
            case arg
                when 'environment'
                    arg = args.shift
                    case
                        when %w(list).include?(arg)
                            # assert(0 == args.length)
                            @cindy.environments.each do |env|
                                puts "- #{env.name}: #{env.uri}"
                            end
                        when %w(delete).include?(arg)
                            # assert(1 == args.length)
                            @cindy.send(:"environment_#{arg}", *args)
                        when %w(create update).include?(arg)
                            # assert(2 == args.length)
                            @cindy.send(:"environment_#{arg}", *args)
                        else
                            envname = arg
                            arg = args.shift
                            case
                                when %w(print deploy).include?(arg)
                                    # assert(1 == args.length)
                                    @cindy.send(:"environment_#{arg}_template", envname, *args)
                                else
                                    raise UnexpectedArgumentError.new "unexpected argument '#{arg}'"
                            end
                    end
                when 'template'
                    arg = args.shift
                    case
                        when %w(list).include?(arg)
                            # assert(0 == args.length)
                            @cindy.templates.each do |tpl|
                                puts "> #{tpl.alias || '(none)'}: #{tpl.file}"
                            end
                        when %w(add delete).include?(arg)
                            # assert(1 == args.length)
                            @cindy.send(:"#{arg}_template", *args)
                        else
                            tplname = arg
                            case args.shift
                                when 'environment'
                                    # assert(args.length >= 2)
                                    envname = args.shift
                                    case args.shift
                                        when 'variable'
                                            # assert(args.length >= 1)
                                            case args.shift
                                                when 'list'
                                                    @cindy.environment_template_variables(envname, tplname)
                                                else
                                                    raise UnexpectedArgumentError.new
                                            end
                                    else
                                        raise UnexpectedArgumentError.new
                                    end
                                else
                                    raise UnexpectedArgumentError.new
                            end
                    end
                else
                    raise UnexpectedArgumentError.new "unexpected argument '#{arg}' instead of 'environment' or 'template'"
            end
        end
    end
end

require 'erb'
require 'uri'
require 'ostruct'

module Cindy
    class Template

        attr_reader :file, :alias, :paths, :defvars, :envvars

        def initialize(file, name)
            @file = file # local template filename
            @alias = name
            @paths = {}   # remote filenames (<environment name> => <filename>)
            @defvars = {} # default/global variables
            @envvars = {} # environment specific variables
        end

        IDENT_STRING = ' ' * 4

        def to_s
            ret = ["template :#{@alias}, #{@file.inspect} do"]
            @defvars.each_pair do |k,v|
                ret << "#{IDENT_STRING * 1}var :#{k}, #{v.inspect}"
            end
            @paths.each_pair do |ke,ve|
               ret << "#{IDENT_STRING * 1}on :#{ke}, #{ve} do"
               @envvars[ke].each_pair do |kv,vv|
                   ret << "#{IDENT_STRING * 2}var :#{kv}, #{vv.inspect}"
               end
               ret << "#{IDENT_STRING * 1}end"
            end
            ret << "end"
            ret << ''
            ret.join "\n"
        end

        def environment_name_updated(oldname, newname)
            @paths[newname] = @paths.delete(oldname) if @paths.key? oldname
            @envvars[newname] = @envvars.delete(oldname) if @envvars.key? oldname
        end

        def update(attributes)
            @file = attributes['file'] if attributes['file']
            @alias = attributes['name'] if attributes['name']
        end

        def print(env)
            puts render(env)
        end

        def deploy(env)
            executor = executor_for_env env
            remote_filename = @paths[env.name]
            sudo = ''
            sudo = 'sudo ' unless 0 == executor.exec('id -u').to_i
            suffix = executor.exec('date \'+%Y%m%d%H%M\'') # use remote - not local - time machine
            executor.exec("[ -e \"#{remote_filename}\" ] && [ ! -h \"#{remote_filename}\" ] && #{sudo} mv -i \"#{remote_filename}\" \"#{remote_filename}.pre\"")
            executor.exec("#{sudo} tee #{remote_filename}.#{suffix} > /dev/null", render(env, executor))
            executor.exec("#{sudo} ln -snf \"#{remote_filename}.#{suffix}\" \"#{remote_filename}\"")
            executor.close
        end

        def variables
            (@defvars.keys + @envvars.collect { |v| v[1].keys }.flatten).uniq
        end

        def list_variables(envname)
            @defvars.merge(@envvars[envname]).each_pair do |k,v|
                puts "- #{k}#{' (default)' unless @envvars[envname].key? k } = #{v} (#{v.class.name})"
            end
        end

        def unset_variable(varname)
            @defvars.delete varname
            @envvars.each_value do |h|
                h.delete varname
            end
        end

        def rename_variable(oldvarname, newvarname)
            @defvars[newvarname] = value if value = @defvars.delete(oldvarname)
            @envvars.each_value do |h|
                h[newvarname] = value if value = h.delete(oldvarname)
            end
        end

        def set_variable(envname, varname, value, type)
            type ||= 'string'
            if envname
                @envvars[envname][varname] = Variable.send(:"parse_#{type}", value)
            else
                @defvars[varname] = Variable.send(:"parse_#{type}", value)
            end
        end

        def set_path_for_environment(envname, path)
            @paths[envname] = path
            @envvars[envname] ||= {}
        end

private

        def executor_for_env(env)
            uri = URI.parse(env.uri)
            case uri.scheme
                when nil, 'file'
                    Executor::Local.new
                when 'ssh'
                    Executor::SSH.new Net::SSH.start(uri.host, uri.user)
                else
                    raise Exception.new 'Unexpected protocol'
            end
        end

        def render(env, executor = nil)
            close_executor = executor.nil?
            executor ||= executor_for_env(env)
            vars = Hash[
                @defvars.merge(@envvars[env.name]).map do |k, v|
                    if v.respond_to? :call
                        [ k, v.call(executor) ]
                    else
                        [ k, v ]
                    end
                end
            ]
            # ||= to not overwrite a previously user defined variable with the same name
            vars['_install_file_'] ||= @paths[env.name]
            vars['_install_dir_'] ||= File.dirname @paths[env.name]
            erb = ERB.new(File.read(@file), 0, '-')
            executor.close if close_executor
            erb.result(OpenStruct.new(vars).instance_eval { binding })
        end

    end
end

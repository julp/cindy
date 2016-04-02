require 'erb'
require 'ostruct'
require 'shellwords'

module Cindy
    class Template

        attr_reader :file, :alias, :paths, :defvars, :envvars, :postcmds

        def initialize(owner, file, name)
            @owner = owner # owner is Cindy objet
            @file = file # local template filename
            @alias = name
            @paths = {}   # remote filenames (<environment name> => <filename>)
            @defvars = {} # default/global variables
            @envvars = {} # environment specific variables
            @postcmds = [] # commands to run after deployment
        end

        IDENT_STRING = ' ' * 4

        def to_s
            ret = ["template :#{@alias}, #{@file.inspect} do"]
            @defvars.each_pair do |k,v|
                ret << "#{IDENT_STRING * 1}var :#{k}, #{v.inspect}"
            end
            @paths.each_pair do |ke,ve|
               ret << "#{IDENT_STRING * 1}on :#{ke}, #{ve.inspect} do"
               @envvars[ke].each_pair do |kv,vv|
                   ret << "#{IDENT_STRING * 2}var :#{kv}, #{vv.inspect}"
               end
               ret << "#{IDENT_STRING * 1}end"
            end
            ret << "end"
            ret << ''
            ret.join "\n"
        end

        def print(env)
            puts render(env)
        end

        def add_postcmd(cmd, options)
            @postcmds << cmd
        end

        def deploy(env)
            executor = executor_for_env env
            remote_filename = @paths[env.name]
            sudo = ''
            sudo = 'sudo' unless 0 == executor.exec('id -u').to_i
            suffix = executor.exec('date \'+%Y%m%d%H%M\'') # use remote - not local - time machine
            executor.exec("[ -e \"#{remote_filename}\" ] && [ ! -h \"#{remote_filename}\" ] && #{sudo} mv -i \"#{remote_filename}\" \"#{remote_filename}.pre\"")
            executor.exec("#{sudo} tee #{remote_filename}.#{suffix} > /dev/null", stdin: render(env, executor))
            executor.exec("#{sudo} ln -snf \"#{remote_filename}.#{suffix}\" \"#{remote_filename}\"")
            shell = executor.exec('ps -p $$ -ocomm=')
            env = { 'INSTALL_FILE' => remote_filename }
            env_string = env.inject([]) { |a, b| a << b.map(&:shellescape).join('=') }.join(' ')
            @postcmds.each do |cmd|
                executor.exec("#{sudo} #{'env' if shell =~ /csh\z/} #{env_string} sh -c '#{cmd}'") # TODO: escape single quotes in cmd?
            end
            executor.close
        end

#         def variables
#             (@defvars.keys + @envvars.collect { |v| v[1].keys }.flatten).uniq
#         end

        def list_variables(envname)
            @defvars.merge(@envvars[envname]).each_pair do |k,v|
                puts "- #{k}#{' (default)' unless @envvars[envname].key? k } = #{v} (#{v.class.name})"
            end
        end

#         def unset_variable(varname)
#             @defvars.delete varname
#             @envvars.each_value do |h|
#                 h.delete varname
#             end
#         end

#         def rename_variable(oldvarname, newvarname)
#             @defvars[newvarname] = value if value = @defvars.delete(oldvarname)
#             @envvars.each_value do |h|
#                 h[newvarname] = value if value = h.delete(oldvarname)
#             end
#         end

        def set_variable(envname, varname, value)
            envname = envname.intern if envname
            varname = varname.intern
            STDERR.puts "[ WARN ] non standard variable name found" unless varname =~ /\A[a-z][a-z0-9_]*\z/
            if envname
                @envvars[envname][varname] = value
            else
                @defvars[varname] = value
            end
        end

        def set_path_for_environment(envname, path)
            envname = envname.intern
            @paths[envname] = path
            @envvars[envname] ||= {}
        end

private

        def executor_for_env(env)
            Executor::Base.from_uri env.uri, @owner.logger
        end

        def render(env, executor = nil)
            close_executor = executor.nil?
            executor ||= executor_for_env(env)
#             shell = executor.exec('ps -p $$ -ocomm=')
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

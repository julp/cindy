require 'erb'
require 'ostruct'
require 'shellwords'

module Cindy
    class Template < Scope

        attr_reader :file, :alias, :postcmds

        def initialize(cindy, file, name)
            super cindy
            @file = file # local template filename
            @alias = name
            @tplenv = {}
            @postcmds = [] # commands to run after deployment
        end

        def define_environment(envname, file)
            envname = envname.intern
            @tplenv[envname] = TplEnv.new(self, file)
        end

        def print(env)
            puts render(env)
        end

        def add_postcmd(cmd, options)
            @postcmds << cmd
        end

        def deploy(env)
            executor = executor_for_env env
            remote_filename = @tplenv[env.name].path
            # TODO: run commands in a sh subshell (we still need to able to get exit value and std(in|out|err) of those subcommands)
            sudo = ''
            sudo = 'sudo' unless 0 == executor.exec('id -u').to_i
#             sudo = 'su - root -c \'' unless 0 == executor.exec('id -u').to_i # to do without sudo on *BSD
            suffix = executor.exec('date \'+%Y%m%d%H%M\'') # use remote - not local - time machine
            executor.exec("[ -e \"#{remote_filename}\" ] && [ ! -h \"#{remote_filename}\" ] && #{sudo} mv -i \"#{remote_filename}\" \"#{remote_filename}.pre\"")
            executor.exec("#{sudo} tee #{remote_filename}.#{suffix} > /dev/null", stdin: render(env, executor))
            executor.exec("#{sudo} ln -snf \"#{remote_filename}.#{suffix}\" \"#{remote_filename}\"")
            shell = executor.exec('ps -p $$ -ocomm=')
            env = { 'INSTALL_FILE' => remote_filename }
            env_string = env.inject([]) { |a, b| a << b.map(&:shellescape).join('=') }.join(' ')
            @postcmds.each do |cmd|
                executor.exec("#{sudo} #{'env' if shell =~ /csh\z/} #{env_string} sh -c '#{cmd}'") # TODO: escape single quotes in cmd?
                # TODO: continue or not on command failure
            end
            executor.close
        end

        IDENT_STRING = ' ' * 4

        def list_variables(envname)
            envname = envname.intern
            @tplenv[envname].trace.each do |k,a|
                puts "- #{k}"
                a.each_with_index do |s,i|
                    v = s.get_variable k
                    puts "#{IDENT_STRING * (i + 1)}+ #{s.class.name} = #{v} (#{v.class.name})"
                end
            end
        end

private

        def executor_for_env(env)
            Executor::Base.from_uri env.uri, @parent.logger
        end

        def render(env, executor = nil)
            close_executor = executor.nil?
            executor ||= executor_for_env(env)
#             shell = executor.exec('ps -p $$ -ocomm=')
            vars = @tplenv[env.name].scope(executor)
            # ||= to not overwrite a previously user defined variable with the same name
            vars['_install_file_'] ||= @tplenv[env.name].path
            vars['_install_dir_'] ||= File.dirname @tplenv[env.name].path
            erb = ERB.new(File.read(@file), 0, '-')
            executor.close if close_executor
            erb.result(OpenStruct.new(vars).instance_eval { binding })
        end

    end
end

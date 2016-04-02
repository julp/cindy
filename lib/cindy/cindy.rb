require 'logger'

module Cindy

    class UndefinedEnvironmentError < ::NameError
    end

    class UndefinedTemplateError < ::NameError
    end

    class AlreadyExistsError < ::NameError
    end

    class Cindy

        # Default location of Cindy's configuration file
        CONFIGURATION_FILE = File.expand_path '~/.cindy'

        module DSL
            class TemplateEnvironmentNode
                def initialize(tpl, envname)
                    @tpl = tpl
                    @envname = envname
                end

                def cmd(command, options = {})
                    Command.new command, options
                end

                def var(varname, value)
                    @tpl.set_variable @envname, varname, value
                end

                alias_method :variable, :var
            end

            class TemplateNode
                def initialize(tpl)
                    @tpl = tpl
                end

                def cmd(command, options = {})
                    Command.new command, options
                end

                def var(varname, value)
                    @tpl.set_variable nil, varname, value
                end

                alias_method :variable, :var

                def on(envname, file, &block)
                    @tpl.set_path_for_environment envname, file
                    TemplateEnvironmentNode.new(@tpl, envname).instance_eval &block if block_given?
                end

                def postcmd(cmd, options = {})
                    @tpl.add_postcmd cmd, options
                end
            end

            class CindyNode
                def initialize(cindy)
                    @cindy = cindy
                end

                def template(tplname, path, &block)
                    tpl = @cindy.template_add tplname, path
                    TemplateNode.new(tpl).instance_eval &block
                    tpl
                end

                def environment(envname, uri = '')
                    @cindy.environment_add envname, uri
                end
            end
        end

        # DSL
        # \@!method environment(envname, uri = '')
        # \@!method template(tplname, path, &block)

        # @return [Logger] the logger associated to the cindy instance
        attr_accessor :logger

        # Creates an "empty" Cindy object
        def initialize
            @environments = {}
            @templates = {}
            @logger = Logger.new STDERR
        end

        # Creates a Cindy object from a string
        #
        # @param string [String] the configuration string to evaluate
        # @return [Cindy]
        def self.from_string(string)
            cindy = Cindy.new
            DSL::CindyNode.new(cindy).instance_eval string
            cindy
        end

        # Creates a Cindy object from a file
        #
        # @param filename [String] the file to evaluate ; default location {CONFIGURATION_FILE} is used if nil
        # @return [Cindy]
        def self.load(filename = nil)
            @filename = filename || CONFIGURATION_FILE
            cindy = Cindy.new
            DSL::CindyNode.new(cindy).instance_eval(File.read(@filename), File.basename(@filename), 0)
            cindy
        end

        def to_s
            (@environments.values.map(&:to_s) + [''] + @templates.values.map(&:to_s)).join("\n")
        end

        # Get known environments
        #
        # @return [Array<Symbol>] list of environment names
        def environments
            @environments.values
        end

        # Does environment exist?
        #
        # @param envname [String, Symbol] the name of the environment to check for existence
        def has_environment?(envname)
            envname = envname.intern
            @environments.key? envname
        end

        # Add a new environment
        #
        # @param envname [String, Symbol] the name of the new environment
        # @param attributes [String] the uri of the host (eg 'ssh://user@1.2.3.4/' for a
        #  remote one or 'file:///' to work directely on actual host)
        # @return [Environment] the registered environment
        def environment_add(envname, attributes)
            envname = envname.intern
            # assert !@environments.key? envname
            @environments[envname] = Environment.new(envname, attributes)
        end

        # Get registered templates
        #
        # @return [Array<Symbol>] list of template names
        def templates
            @templates.values
        end

        # Does template exist?
        #
        # @param tplname [String, Symbol] the name of the template to check for existence
        def has_template?(tplname)
            tplname = tplname.intern
            @templates.key? tplname
        end

        # Add a new template
        #
        # @param tplname [String, Symbol] the name of the new template
        # @param file [String] the location of the template file. Note it is expanded
        #  ({File#expand_path}) to permit usage of ~ so it may be a good idea to avoid
        #  relative paths
        # @return [Template] the registered template
        def template_add(tplname, file)
            tplname = tplname.intern
            # assert !@templates.key? name
            @templates[tplname] = Template.new self, File.expand_path(file), tplname
        end

        # Print on stdout the result of template generation
        #
        # @param envname [String, Symbol] the name of the environment
        # @param tplname [String, Symbol] the name of the template
        # @raise [UndefinedEnvironmentError] if environment does not exist
        # @raise [UndefinedTemplateError] if template does not exist
        def template_environment_print(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].print @environments[envname]
        end

        # Deploy the result of template generation on the given environment
        #
        # @param envname [String, Symbol] the name of the environment
        # @param tplname [String, Symbol] the name of the template
        # @raise [UndefinedEnvironmentError] if environment does not exist
        # @raise [UndefinedTemplateError] if template does not exist
        def template_environment_deploy(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].deploy @environments[envname]
        end

        # Print on stdout a detail (value and scope) of applicable variables
        #
        # @param envname [String, Symbol] the name of the environment
        # @param tplname [String, Symbol] the name of the template
        # @raise [UndefinedEnvironmentError] if environment does not exist
        # @raise [UndefinedTemplateError] if template does not exist
        def template_environment_variables(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].list_variables envname
        end

private

        def check_environment!(envname)
            raise UndefinedEnvironmentError.new "call to an undefined environment: #{envname}" unless has_environment? envname
        end

        def check_template!(tplname)
            raise UndefinedTemplateError.new "call to an undefined template: #{tplname}" unless has_template? tplname
        end

    end
end

module Cindy

    class UndefinedEnvironmentError < ::NameError
    end

    class UndefinedTemplateError < ::NameError
    end

    class AlreadyExistsError < ::NameError
    end

    class Cindy

        CONFIGURATION_FILE = File.expand_path '~/.cindy'

        module DSL
            class TemplateEnvironmentNode
                def initialize(tpl, envname)
                    @tpl = tpl
                    @envname = envname
                end

                def var(varname, value)
                    @tpl.set_variable @envname, varname, value
                end
            end

            class TemplateNode
                def initialize(tpl)
                    @tpl = tpl
                end

                def var(varname, value)
                    @tpl.set_variable nil, varname, value
                end

                alias_method :variable, :var

                def on(envname, file, &block)
                    @tpl.set_path_for_environment envname, file
                    TemplateEnvironmentNode.new(@tpl, envname).instance_eval &block if block_given?
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

                def environment(envname, uri = nil)
                    @cindy.environment_add envname, uri
                end
            end
        end

        def initialize
            @environments = {}
            @templates = {}
        end

        def self.from_string(string)
            cindy = Cindy.new
            DSL::CindyNode.new(cindy).instance_eval string
            cindy
        end

        def self.load(filename = nil)
            @filename = filename || CONFIGURATION_FILE
            cindy = Cindy.new
            DSL::CindyNode.new(cindy).instance_eval(File.read(@filename), File.basename(@filename), 0)
            cindy
        end

        def to_s
            (@environments.values.map(&:to_s) + [''] + @templates.values.map(&:to_s)).join("\n")
        end

        def environments
            @environments.values
        end

        def has_environment?(envname)
            envname = envname.intern
            @environments.key? envname
        end

        def environment_add(envname, attributes)
            envname = envname.intern
            # assert !@environments.key? envname
            @environments[envname] = Environment.new(envname, attributes)
        end

        def templates
            @templates.values
        end

        def has_template?(tplname)
            tplname = tplname.intern
            @templates.key? tplname
        end

        def template_add(tplname, file)
            tplname = tplname.intern
            # assert !@templates.key? name
            @templates[tplname] = Template.new File.expand_path(file), tplname
        end

        def template_environment_print(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].print(@environments[envname])
        end

        def template_environment_deploy(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].deploy(@environments[envname])
        end

        def template_environment_variables(envname, tplname)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].list_variables(envname)
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

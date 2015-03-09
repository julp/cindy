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

                def template(name, path, &block)
                    tpl = @cindy.template_add name, path
                    TemplateNode.new(tpl).instance_eval &block
                    tpl
                end

                def environment(name, uri = nil)
                    @cindy.environment_create name, uri
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

        def environment_delete(envname)
            envname = envname.intern
            @environments.delete envname
        end

        def environment_create(envname, attributes)
            envname = envname.intern
            # assert !@environments.key? envname
            @environments[envname] = Environment.new(envname, attributes)
        end

        def environment_update(envname, attributes)
            envname = envname.intern
            attributes['name'] = attributes['name'].intern if attributes.key? 'name'
            raise AlreadyExistsError.new "an environment named '#{attributes['name']}' already exists" if attributes.key?('name') && @environments.key?(attributes['name'])
            check_environment! envname
            @environments[envname].update attributes
            if attributes.key? 'name'
                @templates.each_value do |tpl|
                    tpl.environment_name_updated envname, attributes['name']
                end
            end
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

        def template_update(tplname, attributes)
            tplname = tplname.intern
            attributes['name'] = attributes['name'].intern if attributes.key? 'name'
            raise AlreadyExistsError.new "a template named '#{attributes['name']}' already exists" if attributes.key?('name') && @templates.key?(attributes['name'])
            check_template! tplname
            @templates[tplname].update attributes
        end

        def template_delete(tplname)
            tplname = tplname.intern
            @templates.delete tplname
        end

        def template_variables(tplname)
            tplname = tplname.intern
            @templates[tplname].variables
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

        def template_variable_unset(tplname, varname)
            tplname = tplname.intern
            varname = varname.intern
            check_template! tplname
            @templates[tplname].unset_variable varname
        end

        def template_variable_rename(tplname, oldvarname, newvarname)
            tplname = tplname.intern
            oldvarname = oldvarname.intern
            newvarname = newvarname.intern
            check_template! tplname
            @templates[tplname].rename_variable oldvarname, newvarname
        end

        def template_variable_set(tplname, varname, value, type)
            tplname = tplname.intern
            varname = varname.intern
            template_environment_variable_set nil, tplname, varname, value, type
        end

        def template_environment_variable_set(envname, tplname, varname, value, type)
            envname = envname.intern
            tplname = tplname.intern
            varname = varname.intern
            check_environment! envname if envname
            check_template! tplname
            STDERR.puts "[ WARN ] non standard variable name found" unless varname =~ /\A[a-z][a-z0-9_]*\z/
            @templates[tplname].set_variable envname, varname, value, type
        end

        def template_environment_path(envname, tplname, path)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].set_path_for_environment @environments[envname], path
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

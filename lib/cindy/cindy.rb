module Cindy

    class UndefinedEnvironmentError < ::NameError
    end

    class UndefinedTemplateError < ::NameError
    end

    class AlreadyExistsError < ::NameError
    end

    class Cindy

        CONFIGURATION_FILE = File.expand_path('~/.cindy2')

        class TemplateEnvironmentNode
            def initialize(tpl, envname)
                @tpl = tpl
                @envname = envname
            end

            def var(varname, value)
                @tpl.set_variable @envname, varname, value, nil
            end
        end

        class TemplateNode
            def initialize(tpl)
                @tpl = tpl
            end

            def var(varname, value)
                @tpl.set_variable nil, varname, value, nil
            end

            def on(envname, file, &block)
                @tpl.set_path_for_environment envname, file
                TemplateEnvironmentNode.new(@tpl, envname).instance_eval &block
            end
        end

        class CindyNode
            def initialize(cindy)
                @cindy = cindy
            end

            def template(name, path, &block)
                tpl = @cindy.template_add path, name
                TemplateNode.new(tpl).instance_eval &block
                tpl
            end

            def environment(name, uri = nil)
                @cindy.environment_create name, uri
            end
        end

        def initialize
            @environments = {}
            @templates = {}
        end

        def self.load
            cindy = Cindy.new
            CindyNode.new(cindy).instance_eval(File.read(CONFIGURATION_FILE), File.basename(CONFIGURATION_FILE), 0)
            cindy
        end

        def save(filename)
#             doc = REXML::Document.new
#             doc << root = REXML::Element.new(self.class.name.split('::').first.downcase)
#             @environments.each_value do |env|
#                 env.to_xml root
#             end
#             @templates.each_value do |tpl|
#                 tpl.to_xml root
#             end
#             formatter = REXML::Formatters::Pretty.new 4
#             formatter.compact = true
#             formatter.write doc, File.open(filename, 'w')
        end

        def environments
            @environments.values
        end

        def environment_delete(name)
            @environments.delete name
            save CONFIGURATION_FILE
        end

        def environment_create(name, properties)
            # assert !@environments.key? name
            @environments[name] = Environment.new(name, properties)
            save CONFIGURATION_FILE
        end

        def environment_update(name, attributes)
            raise AlreadyExistsError.new "an environment named '#{attributes['name']}' already exists" if attributes.key?('name') && @environments.key?(attributes['name'])
            check_environment! name
            @environments[name].update attributes
            if attributes.key? 'name'
                @templates.each_value do |tpl|
                    tpl.environment_name_updated name, attributes['name']
                end
            end
            save CONFIGURATION_FILE
        end

        def templates
            @templates.values.uniq # Set.new(@templates.values) ?
        end

        def template_add(file, name)
            name = name.intern
            # assert !@templates.key? name
            @templates[name] = Template.new File.expand_path(file), name
            save CONFIGURATION_FILE
            @templates[name]
        end

        def template_update(name, attributes)
            name = name.intern
            raise AlreadyExistsError.new "a template named '#{attributes['name']}' already exists" if attributes.key?('name') && @templates.key?(attributes['name'])
            check_template! name
            @templates[name].update attributes
            save CONFIGURATION_FILE
        end

        def template_delete(name)
            name = name.intern
            @templates.delete name
            save CONFIGURATION_FILE
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
            @templates[tplname].list_variables(@environments[envname])
        end

        def template_variable_unset(tplname, varname)
            tplname = tplname.intern
            varname = varname.intern
            check_template! tplname
            @templates[tplname].unset_variable varname
            save CONFIGURATION_FILE
        end

        def template_variable_rename(tplname, oldvarname, newvarname)
            tplname = tplname.intern
            oldvarname = oldvarname.intern
            newvarname = newvarname.intern
            check_template! tplname
            @templates[tplname].rename_variable oldvarname, newvarname
            save CONFIGURATION_FILE
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
            save CONFIGURATION_FILE
        end

        def template_environment_path(envname, tplname, path)
            envname = envname.intern
            tplname = tplname.intern
            check_environment! envname
            check_template! tplname
            @templates[tplname].set_path_for_environment @environments[envname], path
            save CONFIGURATION_FILE
        end

private

        def check_environment!(envname)
            raise UndefinedEnvironmentError.new "call to an undefined environment: #{envname}" unless @environments[envname]
        end

        def check_template!(tplname)
            raise UndefinedTemplateError.new "call to an undefined template: #{tplname}" unless @templates[tplname]
        end

    end
end

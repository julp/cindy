require 'rexml/document'

module Cindy

    class UndefinedEnvironmentError < ::NameError
    end

    class UndefinedTemplateError < ::NameError
    end

    class AlreadyExistsError < ::NameError
    end

    class Cindy

        CONFIGURATION_FILE = File.expand_path('~/.cindy')

        def initialize
            @environments = {}
            @templates = {}
            load CONFIGURATION_FILE
        end

        def load(filename)
            if File.exist? filename
                file = File.new filename
                doc = REXML::Document.new file
                Environment.from_xml(@environments, doc.root)
                Template.from_xml(@templates, doc.root)
            end
        end

        def save(filename)
            doc = REXML::Document.new
            doc << root = REXML::Element.new(self.class.name.split('::').first.downcase)
            @environments.each_value do |env|
                env.to_xml root
            end
            @templates.each_value do |tpl|
                tpl.to_xml root
            end
            formatter = REXML::Formatters::Pretty.new 4
            formatter.compact = true
            formatter.write doc, File.open(filename, 'w')
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
            # assert !@templates.key? name
            @templates[name] = Template.new File.expand_path(file), name
            save CONFIGURATION_FILE
        end

        def template_update(name, attributes)
            raise AlreadyExistsError.new "a template named '#{attributes['name']}' already exists" if attributes.key?('name') && @templates.key?(attributes['name'])
            check_template! name
            @templates[name].update attributes
            save CONFIGURATION_FILE
        end

        def template_delete(name)
            @templates.delete name
            save CONFIGURATION_FILE
        end

        def template_environment_print(envname, tplname)
            check_environment! envname
            check_template! tplname
            @templates[tplname].print(@environments[envname])
        end

        def template_environment_deploy(envname, tplname)
            check_environment! envname
            check_template! tplname
            @templates[tplname].deploy(@environments[envname])
        end

        def template_environment_variables(envname, tplname)
            check_environment! envname
            check_template! tplname
            @templates[tplname].list_variables(@environments[envname])
        end

        def template_variable_unset(tplname, varname)
            check_template! tplname
            @templates[tplname].unset_variable varname
            save CONFIGURATION_FILE
        end

        def template_variable_rename(tplname, oldvarname, newvarname)
            check_template! tplname
            @templates[tplname].rename_variable oldvarname, newvarname
            save CONFIGURATION_FILE
        end

        def template_variable_set(tplname, varname, value, type)
            template_environment_variable_set nil, tplname, varname, value, type
        end

        def template_environment_variable_set(envname, tplname, varname, value, type)
            check_environment! envname if envname
            check_template! tplname
            STDERR.puts "[ WARN ] non standard variable name found" unless varname =~ /\A[a-z][a-z0-9_]*\z/
            @templates[tplname].set_variable @environments[envname], varname, value, type
            save CONFIGURATION_FILE
        end

        def template_environment_path(envname, tplname, path)
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

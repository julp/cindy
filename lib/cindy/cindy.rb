require 'rexml/document'

module Cindy
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
            @environments[name] = Environment.new(name, properties)
            save CONFIGURATION_FILE
        end

        def templates
            @templates.values.uniq # Set.new(@templates.values) ?
        end

        def template_add(file, name)
            @templates[name] = Template.new File.expand_path(file), name
            save CONFIGURATION_FILE
        end

        def template_delete(name)
            @templates.delete name
            save CONFIGURATION_FILE
        end

        def environment_print_template(envname, tplname)
            @templates[tplname].print(@environments[envname])
        end

        def environment_deploy_template(envname, tplname)
            @templates[tplname].deploy(@environments[envname])
        end

        def environment_template_variables(envname, tplname)
            @templates[tplname].list_variables(@environments[envname])
        end

        def template_variable_delete(tplname, varname)
            @templates[tplname].delete_variable varname
            save CONFIGURATION_FILE
        end
    end
end

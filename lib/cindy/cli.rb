require 'thor'

module Cindy
    class CLI < ::Thor

        {
            deploy:    "Install the generated file on the given environment",
            variables: "List all applicable variables to the given template, their values and scopes",
            print:     "Display output configuration file as it would be deployed on the given environment",
        }.each do |name, help|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
                option :template, required: true, aliases: %w(t tpl)
                option :environment, required: true, aliases: %w(e env)
                desc "#{name}", "#{help}"
                def #{name}
                    @cindy = Cindy.load ENV['CINDY_CONF']
                    @cindy.template_environment_#{name}(options[:environment], options[:template])
                end
            RUBY
        end

        desc "", ""
        def templates
            @cindy = Cindy.load ENV['CINDY_CONF']
            @cindy.templates.each do |tpl|
                puts "> #{tpl.alias}: #{tpl.file}"
            end
        end

        desc "", ""
        def environments
            @cindy = Cindy.load ENV['CINDY_CONF']
            @cindy.environments.each do |env|
                puts "- #{env.name}: #{env.uri}"
            end
        end

    end
end

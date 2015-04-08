require 'uri'
require 'net/ssh'

module Cindy
    module Executor
        class SSH < Base
            def self.handle?(uri)
                'ssh' == uri.scheme
            end

            def initialize(uri, logger)
                @cnx = Net::SSH.start(uri.host, uri.user)
                super logger
            end

            def exec_imp(command, stdin_str)
                exit_status = 1
                stdout_str = stderr_str = ''
                @cnx.open_channel do |channel|
                    channel.exec(command) do |ch, success|
                        channel.on_data do |ch, data|
                            stdout_str += data
                        end
                        channel.on_extended_data do |ch, type, data|
                            stderr_str += data
                        end
                        channel.on_request 'exit-status' do |ch, data|
                            exit_status = data.read_long
                        end
                        channel.send_data stdin_str.force_encoding('ASCII-8BIT') if stdin_str
                        channel.eof!
                    end
                end
                @cnx.loop
                [ stdout_str, stderr_str, exit_status ]
            end

            def close
                @cnx.close
            end
        end
    end
end

require 'net/ssh'

module Cindy
    module Executor
        class SSH
            def initialize(cnx)
                @cnx = cnx
            end

            def exec(command, stdin_str = nil, status_only = false)
                exit_status = 1
#                 if stdin_str
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
                            channel.send_data stdin_str if stdin_str
                            channel.eof!
                        end
                    end
                    @cnx.loop
#                 else
#                     result = @cnx.exec!(command)
#                     result.chomp if result.respond_to? :chomp # as result can be nil <=> result.chomp if result <=> result.try? :chomp (rails way)
#                 end
                return nil if status_only && 0 != exit_status
                stdout_str.chomp
            end

            def close
                @cnx.close
            end
        end
    end
end

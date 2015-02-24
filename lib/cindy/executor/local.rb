require 'open3'

module Cindy
    module Executor
        class Local
            def exec(command, stdin_str = nil, status_only = false)
                exit_status = 1
                stdout_str = stderr_str = ''
                Open3.popen3({ 'PATH' => "#{ENV['PATH']}:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin" }, command) do |stdin, stdout, stderr, wait_thr|
                    if stdin_str
                        stdin.write stdin_str
                        stdin.close
                    end
                    stdout_str = stdout.read
                    stderr_str = stderr.read
                    exit_status = wait_thr.value
                end
# puts [ command, stderr_str, exit_status ].inspect
                raise Exception.new if 0 != exit_status && !stderr_str.empty?
                return nil if status_only && 0 != exit_status
                stdout_str.chomp
            end

            def close
                # NOP
            end
        end
    end
end

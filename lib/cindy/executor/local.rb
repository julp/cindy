require 'open3'

module Cindy
    module Executor
        class Local < Base
            def exec_imp(command, stdin_str)
                exit_status = 1
                stdout_str = stderr_str = ''
                begin
                    Open3.popen3({ 'PATH' => "#{ENV['PATH']}:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin" }, command) do |stdin, stdout, stderr, wait_thr|
                        if stdin_str
                            stdin.write stdin_str
                            stdin.close
                        end
                        stdout_str = stdout.read
                        stderr_str = stderr.read
                        exit_status = wait_thr.value.exitstatus
                    end
                rescue Errno::ENOENT => e
                    stderr_str = e.message
                end
                [ stdout_str, stderr_str, exit_status ]
            end
        end
    end
end

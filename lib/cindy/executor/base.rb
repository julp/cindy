module Cindy
    module Executor
        class Base
            # X
            #
            # @param [Logger] logger
            def initialize(logger)
                @logger = logger
            end

            # Executes the given command
            #
            # @param command [String] the command to execute
            # @param options [Hash] the options to execute the command with
            # @option options [String] :stdin the string to send as/on stdin
            # @option options [Boolean] :abort_on_failure abort if true when the command return a non 0 exit value
            # @option options [Hash] :env the environment variables to set/pass for command execution
            # @option options [Boolean] :status_only
            # @return [String, Boolean]
            def exec(command, options = {})
                stdout, stderr, status = exec_imp command, options[:stdin]
                stdout.chomp!
                if status.zero?
                    if stdout.empty?
                        @logger.info 'Command "%s" executed successfully' % command
                    else
                        @logger.info 'Command "%s" executed successfully with "%s" returned)' % [ command, stdout ]
                    end
                else
                    @logger.error 'Command "%s" failed with "%s"' % [ command, stderr ]
                end
                abort 'XXX' if options[:abort_on_failure] && 0 != exit_status
                return status.zero? if options[:status_only]
                stdout
            end

            # Close the eventual underlaying connection
            def close
                # NOP
            end

protected

            # @abstract
            # @param command [String] the command to execute
            # @return [Array<(String, String, Fixnum)>] an array containing the following elements (in this order):
            # 1. output on stdout
            # 2. output on stderr
            # 3. exit status
            def exec_imp(command, stdin_str)
                raise NotImplementedError.new
            end
        end
    end
end

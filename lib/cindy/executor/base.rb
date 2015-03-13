require 'uri'

module Cindy
    module Executor
        class CommandFailedError < StandardError
        end

        class Base
            # X
            #
            # @param [Logger] logger
            def initialize(logger)
                @logger = logger
            end

            def self.from_uri(uri, logger)
                uri = URI.parse(uri)
                ObjectSpace.each_object(Class).select { |v| v.ancestors.include?(self) && v.handle?(uri) }.first.new(uri, logger) or raise Exception.new 'Unexpected protocol'
            end

            # Executes the given command
            #
            # @param command [String] the command to execute
            # @param options [Hash] the options to execute the command with
            # @option options [String] :stdin the string to send as/on stdin
            # @option options [Boolean] :ignore_failure don't raise an exception if true when the command returns a non 0 exit value
            # @option options [Hash] :env the environment variables to set/pass for command execution
            # @option options [Boolean] :check_status_only simply return true if the command is successful else false
            # @return [String, Boolean]
            def exec(command, options = {})
                stdout, stderr, status = exec_imp command, options[:stdin]
                stdout.chomp!
                # <logging>
                if status.zero?
                    if stdout.empty?
                        @logger.info 'Command "%s" executed successfully' % command
                    else
                        @logger.info 'Command "%s" executed successfully (with "%s" returned)' % [ command, stdout ]
                    end
                else
                    @logger.send(options[:ignore_failure] ? :warn : :error, 'Command "%s" failed with "%s"' % [ command, stderr ])
                end
                # </logging>
                return status.zero? if options[:check_status_only]
                raise CommandFailedError.new "Command '#{command}' failed" if !options[:ignore_failure] && 0 != status
                stdout
            end

            # Close the eventual underlaying connection
            def close
                # NOP
            end

protected

            # @abstract
            def self.handle?(uri)
                false
            end

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

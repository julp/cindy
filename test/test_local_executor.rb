require 'logger'
require 'minitest_helper'

class LocalExecutorTest < Minitest::Test

    def test_local_executor
        logger = Logger.new File.open('/dev/null', File::WRONLY)
        locexec = Cindy::Executor::Local.new logger
        # unknown command
        assert_raises Cindy::Executor::CommandFailedError do
            locexec.exec "eko foo"
        end
        assert_equal '', locexec.exec("eko foo", ignore_failure: true)
        assert !locexec.exec("eko foo", ignore_failure: true, check_status_only: true)
        # command failure
        assert_raises Cindy::Executor::CommandFailedError do
            locexec.exec 'grep -q foo', stdin: 'bar'
        end
        assert_equal '', locexec.exec("grep -q foo", stdin: 'bar', ignore_failure: true)
        assert !locexec.exec("grep -q foo", stdin: 'bar', ignore_failure: true, check_status_only: true)
        # valid command
        assert_equal 'foo', locexec.exec('echo foo')
        assert_equal 'foo', locexec.exec('echo foo', ignore_failure: true)
        assert locexec.exec('echo foo', ignore_failure: true, check_status_only: true)
    end

end

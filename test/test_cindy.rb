require 'logger'
require 'minitest_helper'

class CindyTest < Minitest::Test

    def test_deploy
        cindy = Cindy::Cindy.from_string <<-EOS
            environment :foo, 'file:///'

            template :bar, '#{File.join(__dir__, 'templates', 'deploy.tpl')}' do
                on :foo, '/tmp/#{$$}'
            end
        EOS
        cindy.logger = Logger.new File.open('/dev/null', File::WRONLY)

        cindy.template_environment_deploy :foo, :bar
        assert File.symlink?("/tmp/#{$$}")
    end

end

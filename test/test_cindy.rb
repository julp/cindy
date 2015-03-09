require 'minitest_helper'

class CindyTest < Minitest::Test

    def test_overwrite
        cindy = Cindy::Cindy.new
        cindy.template_add 'foo', ''
        cindy.template_add 'bar', ''
        assert_raises Cindy::AlreadyExistsError do
            cindy.template_update 'foo', 'name' => 'bar'
        end
    end

end

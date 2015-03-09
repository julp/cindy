require 'minitest_helper'

class DSLTest < Minitest::Test

    def test_on_without_block
        cindy = Cindy::Cindy.from_string <<-EOS
            environment :foo

            template :bar, 'abc' do
                on :foo, 'def'
            end
        EOS

        tpl = cindy.templates[0]
        assert_equal tpl.alias, :bar
        assert_equal tpl.paths[:foo], 'def'
    end

    def test_string_equivalent_to_symbol
        cindy = Cindy::Cindy.from_string <<-EOS
            environment 'foo'

            template 'bar', 'abc' do
                on 'foo', 'def' do
                    var 'x', 'y'
                end
            end
        EOS

        assert cindy.has_environment? :foo
        assert cindy.has_environment? 'foo'
        assert cindy.has_template? :bar
        assert cindy.has_template? 'bar'
        tpl = cindy.templates[0]
        assert tpl.envvars.key? :foo
#         assert tpl.has_variable? :x
#         assert tpl.has_variable? 'x'
    end

end

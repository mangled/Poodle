require 'rubygems'
require 'test/unit'
require 'text_utilities'

class TestTextUtilities < Test::Unit::TestCase
  
  def test_not_very_much # This could be better/more exhaustive!
    test = '1234567890123456789012345678901234567890'
    assert_equal test, TextUtilities.wrap(test, 10, '*')
    
    test = '1234567890 123456789012345678901234567890'
    assert_equal '1234567890* 123456789012345678901234567890', TextUtilities.wrap(test, 10, '*')
    
    test = '123456789<span class="highlight">0</span> 1234567890 1234567890'
    assert_equal '123456789<span class="highlight">0</span>* 1234567890* 1234567890', TextUtilities.wrap(test, 10, '*')
  end

end

require 'test_helper'

class SearchEventTest < ActiveSupport::TestCase
  
  # Not bothering checking time stamps, nothing else to test for now!
  test "can create" do
    search_event = SearchEvent.new
    assert search_event.valid?
  end

end

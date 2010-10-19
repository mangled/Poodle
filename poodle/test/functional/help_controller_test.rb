require 'test_helper'

class HelpControllerTest < ActionController::TestCase
  test "index" do
    get :index, :search_term => "foo", :start_index => "bar"
    assert_response :success
    assert_equal "foo", assigns[:search_term]
    assert_equal "bar", assigns[:start_index]
  end
end

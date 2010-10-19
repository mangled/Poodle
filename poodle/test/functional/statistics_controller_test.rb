require 'test_helper'

class StatisticsControllerTest < ActionController::TestCase
  # Are there more tests to-do, e.g. no data?
  test "index" do
    graph = OpenStruct.new()
    graph.title = Settings.stats_hits_per_day_title
    graph.no_data_message = Settings.stats_hits_per_day_no_data
    graph.minimum_value = 0
    graph.labels = [[0, "foo"]]
    graph.data = [['search count', []]]

    ClickedEvent.expects(:graph_of_last_seven_days_hits).with(Date.today - 6).returns(graph)
    get :index, :search_term => "foo", :start_index => "bar"
    assert_response :success
    assert_equal graph, assigns[:graph]
    assert_equal "foo", assigns[:search_term]
    assert_equal "bar", assigns[:start_index]
  end
end

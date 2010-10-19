require 'test_helper'

class ClickedEventTest < ActiveSupport::TestCase

  test "attributes must not be empty" do
    clicked_event = ClickedEvent.new
    assert clicked_event.invalid?
    assert clicked_event.errors[:clicked_url_id].any?
  end

  test "newfor with existing url" do
    assert Url.find_by_url(urls(:clicked_once_foo_dot_com).url)
    assert_no_difference('Url.count', 'Existing url entry should be re-used') do
      assert_difference('ClickedEvent.count', 1, 'Search event should be created') do
        ClickedEvent.new_for(urls(:clicked_once_foo_dot_com).url)
        last_clicked_event = ClickedEvent.find(:last)
        assert_equal urls(:clicked_once_foo_dot_com).id, last_clicked_event.clicked_url_id
      end
    end
  end
  
  test "new_for with new url" do
    url = 'http://wizzo.com'
    assert_nil Url.find_by_url(url)
    assert_difference(['Url.count', 'ClickedEvent.count'], 1, 'Search records should be created') do
      ClickedEvent.new_for(url)
      last_clicked_url = Url.find(:last)
      last_clicked_event = ClickedEvent.find(:last)
      assert_equal last_clicked_url.id, last_clicked_event.clicked_url_id
    end
  end
  
  test "graph_of_last_seven_days_hits no hits made" do
    from = Date.parse('2000-01-01')
    graph = ClickedEvent.graph_of_last_seven_days_hits(from)
    assert_equal Settings.stats_hits_per_day_title, graph.title
    assert_equal Settings.stats_hits_per_day_no_data, graph.no_data_message
    assert_equal 0, graph.minimum_value
    assert_equal labels(from.wday), graph.labels
    assert_equal [[Settings.stats_hits_per_day_clicked_count_text, [0, 0, 0, 0, 0, 0, 0]],
      [Settings.stats_hits_per_day_search_count_text, [0, 0, 0, 0, 0, 0, 0]]], graph.data
  end

  test "graph_of_last_seven_days_hits" do
    from = Date.parse('2010-09-30')
    graph = ClickedEvent.graph_of_last_seven_days_hits(from)
    assert_equal labels(from.wday), graph.labels
    assert_equal [[Settings.stats_hits_per_day_clicked_count_text, [0, 1, 2, 3, 4, 5, 6]],
      [Settings.stats_hits_per_day_search_count_text, [0, 1, 2, 3, 4, 5, 6]]], graph.data

    from = Date.parse('2010-10-01')
    graph = ClickedEvent.graph_of_last_seven_days_hits(from)
    assert_equal labels(from.wday), graph.labels
    assert_equal [[Settings.stats_hits_per_day_clicked_count_text, [1, 2, 3, 4, 5, 6, 7]],
      [Settings.stats_hits_per_day_search_count_text, [1, 2, 3, 4, 5, 6, 7]]], graph.data
    
    from = Date.parse('2010-10-02')
    graph = ClickedEvent.graph_of_last_seven_days_hits(from)
    assert_equal labels(from.wday), graph.labels
    assert_equal [[Settings.stats_hits_per_day_clicked_count_text, [2, 3, 4, 5, 6, 7, 0]],
      [Settings.stats_hits_per_day_search_count_text, [2, 3, 4, 5, 6, 7, 0]]], graph.data
    
    from = Date.parse('2010-10-07')
    graph = ClickedEvent.graph_of_last_seven_days_hits(from)
    assert_equal labels(from.wday), graph.labels
    assert_equal [[Settings.stats_hits_per_day_clicked_count_text, [7, 0, 0, 0, 0, 0, 0]],
      [Settings.stats_hits_per_day_search_count_text, [7, 0, 0, 0, 0, 0, 0]]], graph.data
  end

  # Helpers
  def labels(wday)
    days = []
    for i in wday..(wday + 6)
      days << [i - wday, Date::ABBR_DAYNAMES[(i % 7)]]
    end
    days
  end

end

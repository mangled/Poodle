require 'test_helper'

class SearchControllerTest < ActionController::TestCase

  def setup
    # This must be set to align to the controllers usage of settings
    @hits_per_page = Settings.search_results_per_page
  end
  
  test "test_browser_settings_error" do
    get :browser_settings_error
    assert_response :success
    assert_equal 1, flash.length
    assert_equal Settings.browser_fail, flash[:notice]
    assert_equal false, assigns(:stop_check_browser)
  end

  test "search_result_clicked no url" do
    assert_no_difference(['Url.count', 'ClickedEvent.count'], 'No search record should be created') do
      post :search_result_clicked
      assert_response :success
      assert_equal 0, session.length
    end
  end

  test "search_result_clicked with new url" do
    url = 'http://wizzo.com'
    assert_nil Url.find_by_url(url)
    assert_difference(['Url.count', 'ClickedEvent.count'], 1, 'Search records should be created') do
      post :search_result_clicked, :url => 'http://wizzo.com'
      assert_response :success
      last_clicked_url = Url.find(:last)
      last_clicked_event = ClickedEvent.find(:last)
      assert_equal last_clicked_url.id, last_clicked_event.clicked_url_id
    end
  end

  test "search_result_clicked with existing url" do
    assert Url.find_by_url(urls(:clicked_once_foo_dot_com).url)
    assert_no_difference('Url.count', 'Existing url entry should be re-used') do
      assert_difference('ClickedEvent.count', 1, 'Search event should be created') do
        post :search_result_clicked, :url => urls(:clicked_once_foo_dot_com).url
        assert_response :success
        last_clicked_event = ClickedEvent.find(:last)
        assert_equal urls(:clicked_once_foo_dot_com).id, last_clicked_event.clicked_url_id
      end
    end
  end

  test "index blank on get no search submitted" do
    assert_no_difference('SearchEvent.count', 'no search event created') do
      get :index
      assert_response :success
      assert_not_nil assigns(:revision)
      assert_nil assigns(:results)
      assert_equal 0, assigns(:time)
      assert_nil assigns(:start_index)
      assert_nil assigns(:back_index)
      assert_nil assigns(:next_index)
      assert_equal 0, flash.length
      assert_equal 0, session.length
    end
  end

  test "empty search term" do
    assert_no_difference('SearchEvent.count', 'no search event created') do
      search_term = ''
      get :index, :search_term => search_term
      assert_response :success
      assert_not_nil assigns(:revision)
      assert_nil assigns(:results)
      assert_equal 0, assigns(:time)
      assert_nil assigns(:start_index)
      assert_nil assigns(:back_index)
      assert_nil assigns(:next_index)
      assert_equal 0, flash.length
      assert_equal 0, session.length
    end
  end
  
  test "with search term no hits" do
    assert_difference('SearchEvent.count', 1, 'search event created') do
      search_term = 'earwig'
      Solr.expects(:find).with(search_term, "http://localhost:8983/solr", 0, @hits_per_page).returns([])
      get :index, :search_term => search_term
      assert_response :success
      assert_not_nil assigns(:revision)
      assert_not_nil assigns(:results)
      assert_equal 0, assigns(:time)
      assert_equal 0, assigns(:start_index)
      assert_nil assigns(:back_index)
      assert_nil assigns(:next_index)
      assert_equal 0, flash.length
      assert_equal 0, session.length
    end
  end

  # Not this is tied to how lib/solr.rb handles errors, see its unit test also
  test "solr fails connection etc" do
    search_term = 'bang!'
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", 0, @hits_per_page).raises(RuntimeError)
    
    get :index, :search_term => search_term

    assert_response :success
    assert_not_nil assigns(:revision)
    assert_nil assigns(:results)
    assert_equal 0, assigns(:time)
    assert_nil assigns(:back_index)
    assert_nil assigns(:next_index)
    assert_nil assigns(:start_index)
    assert_nil assigns(:search_term)
    assert_equal 1, flash.length
    assert_equal Settings.solr_fail, flash[:notice]
    assert_equal 1, session.length
  end

  test "initial search" do
    def do_get(search_term, next_index)
      get :index, :search_term => search_term
    end
    assert_forward_index_combinations(0, method(:do_get))
  end

  test "next index" do
    def do_get(search_term, next_index)
      get :index, :search_term => search_term, :next_index => next_index.to_s
    end
    assert_forward_index_combinations(@hits_per_page, method(:do_get))
  end

  test "back index" do
    search_term = 'otter'
  
    # Case1: Back from "middle", i.e. more available to go back to
    expected_results = make_expectations(@hits_per_page)
    back_index = @hits_per_page
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", back_index, @hits_per_page).returns(expected_results)
  
    get :index, :search_term => search_term, :back_index => back_index.to_s
    check_assignments_and_session(search_term, expected_results, back_index)

    # Case2: Back goes to start
    expected_results = make_expectations(@hits_per_page)
    back_index = 0
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", back_index, @hits_per_page).returns(expected_results)
  
    get :index, :search_term => search_term, :back_index => back_index.to_s
    check_assignments_and_session(search_term, expected_results, back_index)
  end
  
  # Helpers
  #########
  
  def assert_forward_index_combinations(start_index, action)

    search_term = 'snowball'

    # Case1: Results empty
    expected_results = make_expectations(nil)
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", start_index, @hits_per_page).returns(expected_results)
    action.call(search_term, start_index)
    check_assignments_and_session(search_term, expected_results, start_index)
  
    # Case2: Results < hits_per_page
    expected_results = make_expectations(@hits_per_page - 1)
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", start_index, @hits_per_page).returns(expected_results)
    action.call(search_term, start_index)
    check_assignments_and_session(search_term, expected_results, start_index)
  
    # Case3: Results == hits_per_page
    expected_results = make_expectations(@hits_per_page)
    Solr.expects(:find).with(search_term, "http://localhost:8983/solr", start_index, @hits_per_page).returns(expected_results)
    action.call(search_term, start_index)
    check_assignments_and_session(search_term, expected_results, start_index)
  end

  def make_expectations(number_of)
    expected_results = []
    for i in 1..number_of
      expected_results << {:url => "http://foo.com/#{i}", :keywords => ["#{i}","a","b"], :title => "Snow#{i}", :text => "Eat snow #{i} times"}
    end unless number_of.nil?
    expected_results
  end

  def check_assignments_and_session(search_term, expected_results, current_index)
    # Fairly static checks
    assert_response :success
    assert_not_nil assigns(:revision)
    assert_not_nil assigns(:time)
    assert_equal search_term, assigns(:search_term)
    assert_equal expected_results, re_symbolize_results(assigns(:results))
    assert_equal 0, session.length
    assert_equal 0, flash.length

    # Indexing checks
    assert_equal current_index, assigns(:start_index)
    expected_back_index = (current_index >= @hits_per_page) ? current_index - @hits_per_page : nil
    expected_next_index = (expected_results.length < @hits_per_page) ? nil : current_index + @hits_per_page
    assert_equal expected_back_index, assigns(:back_index), "back_index"
    assert_equal expected_next_index, assigns(:next_index), "next_index"
  end

  def re_symbolize_results(results)
    symbolized_results = []
    results.each do |result|
        temp = {}
        result.each {|key, val| temp[key.to_sym] = val }
        symbolized_results << temp
    end
    symbolized_results
  end

end

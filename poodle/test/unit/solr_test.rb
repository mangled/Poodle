class SolrTest < Test::Unit::TestCase
  
  def test_no_connection
    # Will fail if solr is running on this port! See search_controller_test as it checks this as well
    assert_raise(RuntimeError) {
      Solr.find('foo', 'http://localhost:1234/solr', 0, 10)
    }
  end

  def test_query_no_results
    term = 'foo'
    solr = 'http://localhost:8983/solr'
    start = 0
    rows = 10

    connection = mock()

    connection.expects(:select).with(
      {:q => term, :start=> start, :rows=> rows, :wt => :ruby, :hl=>"on", "hl.fl" =>"search", :fl =>"id,url,keywords,title,crawled_title"}
    ).returns({ "response" => { "docs" => [] }, "highlighting" => {} })

    RSolr.expects(:connect).with(:url => "http://localhost:8983/solr").returns(connection)

    assert_equal [], Solr.find(term, solr, start, rows)
  end
  
  def test_query_results_retain_order
    term = 'foo'
    solr = 'http://localhost:8983/solr'
    start = 0
    rows = 10
    
    connection = mock()

    expected_docs = []
    expected_docs << doc("3", "z", [], "", nil)
    expected_docs << doc("2", "y", [], "", nil)
    expected_docs << doc("1", "x", [], "", nil)

    connection.expects(:select).with(
      {:q => term, :start=> start, :rows=> rows, :wt => :ruby, :hl=>"on", "hl.fl" =>"search", :fl =>"id,url,keywords,title,crawled_title"}
    ).returns({ "response" => { "docs" => expected_docs }, "highlighting" => {} })

    RSolr.expects(:connect).with(:url => "http://localhost:8983/solr").returns(connection)

    results = Solr.find(term, solr, start, rows)
    assert_equal 3, results.length
    assert_equal "z", results[0][:url]
    assert_equal "y", results[1][:url]
    assert_equal "x", results[2][:url]
  end

  def test_title_formatting
    # id, url, titles, keywords, crawled_title
    
    # If the crawled title is present use it
    check_title_formatting(doc("1", "url", [], "", "crawled title"), "crawled title", [])
    check_title_formatting(doc("1", "url", ["a"], "", "crawled title"), "crawled title", [])
    check_title_formatting(doc("1", "url", ["a"], "b", "crawled title"), "crawled title", ["b"])

    # If a solr title exists then use it
    check_title_formatting(doc("1", "url", ["a"], "", ""), "a", [])
    check_title_formatting(doc("1", "url", ["a"], "", nil), "a", [])
    check_title_formatting(doc("1", "url", ["a", "b"], "", nil), "a", [])
    check_title_formatting(doc("1", "url", ["f"], "x", nil), "f", ["x"])
    check_title_formatting(doc("1", "url", ["v"], "x,y", nil), "v", ["x", "y"])
    
    # Check keywords not in title
    check_title_formatting(doc("1", "url", ["a"], "crawled title", "crawled title"), "crawled title", [])
    check_title_formatting(doc("1", "url", ["v"], "v", nil), "v", [])
    check_title_formatting(doc("1", "url", ["v"], "x,v", nil), "v", ["x"])

    # Else use the first keyword, or if we have to the url
    check_title_formatting(doc("1", "url", [], "", nil), "url", [])
    check_title_formatting(doc("1", "url", [], "a", nil), "a", [])
    check_title_formatting(doc("1", "url", [], "a,b", nil), "a", ["b"])
    check_title_formatting(doc("1", "url", [], "a,b,c", nil), "a", ["b", "c"])
  end

  def test_text_stripping
    term = 'bar'
    solr = 'http://localhost:8983/solr'
    start = 4
    rows = 10

    text = "\t some            space! "

    connection = mock()
    connection.expects(:select).with(
      {:q => term, :start=> start, :rows=> rows, :wt => :ruby, :hl=>"on", "hl.fl" =>"search", :fl =>"id,url,keywords,title,crawled_title"}
    ).returns({ "response" => { "docs" => [ doc("1", "url", [], "", "") ] }, "highlighting" => { "1" => highlight(text) } })
    
    RSolr.expects(:connect).with(:url => solr).returns(connection)

    results = Solr.find(term, solr, start, rows)
    assert_equal "some space!", results[0][:text]
  end

  def check_title_formatting(doc, expected_title, expected_keywords)
    term = 'bar'
    solr = 'http://localhost:8983/solr'
    start = 4
    rows = 10

    connection = mock()
    connection.expects(:select).with(
      {:q => term, :start=> start, :rows=> rows, :wt => :ruby, :hl=>"on", "hl.fl" =>"search", :fl =>"id,url,keywords,title,crawled_title"}
    ).returns({ "response" => { "docs" => [ doc ] }, "highlighting" => {} })

    RSolr.expects(:connect).with(:url => solr).returns(connection)

    results = Solr.find(term, solr, start, rows)
    assert_not_nil results
    assert_equal 1, results.length
    assert_equal 4, results[0].length
    assert_equal "url", results[0][:url]
    assert_equal expected_keywords, results[0][:keywords]
    assert_equal expected_title, results[0][:title]
    assert_equal "", results[0][:text]
  end

  def doc(id, url, titles, keywords, crawled_title)
    {"id" => id, "url" => url, "title" => titles, "keywords" => keywords, "crawled_title" => crawled_title }
  end

  def highlight(text)
    { "search" => [text] }
  end

end

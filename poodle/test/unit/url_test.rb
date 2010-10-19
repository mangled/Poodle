require 'test_helper'

class UrlTest < ActiveSupport::TestCase
  fixtures :urls

  test "attributes must not be empty" do
    url = Url.new
    assert url.invalid?
    assert url.errors[:url].any?
    assert url.errors[:click_count].any?
  end
  
  test "url count must be positive" do
    url = Url.new(:url => "hello")
    url.click_count = -1
    assert url.invalid?
    assert_equal "must be greater than or equal to 0", url.errors[:click_count].join('; ')
    url.click_count = 0
    assert url.valid?
  end

  test "url's must be unique" do
    url = Url.new(:url => urls(:clicked_once_foo_dot_com).url, :click_count => "0")
    assert !url.save
    assert_equal "has already been taken", url.errors[:url].join('; ')
  end
  
  test "save_click_count increments an existing url's count" do
    Url.save_click_count(urls(:clicked_once_foo_dot_com).url)
    assert 2, urls(:clicked_once_foo_dot_com).click_count
  end

  test "save_click_count adds a new model for a new url" do
    url = 'http://bar.com/'
    assert !Url.find_by_url(url)
    Url.save_click_count(url)
    new_url = Url.find_by_url(url)
    assert new_url
    assert_equal url, new_url.url
    assert_equal 1, new_url.click_count
  end

end

class Url < ActiveRecord::Base
  
  has_many :search_events, :dependent => :destroy

  validates :url, :click_count, :presence => true
  validates :url, :uniqueness => true
  validates :click_count, :numericality => {:greater_than_or_equal_to => 0}

  def self.save_click_count(url)
    url = find_by_url(url)||Url.new(:url => url, :click_count => 0)
    url.click_count += 1
    url.save
    url
  end

end

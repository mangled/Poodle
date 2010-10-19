class ClickedEvent < ActiveRecord::Base
  require 'ostruct'

  validates :clicked_url_id, :presence => true

  belongs_to :clicked_url

  def self.new_for(url)
    clicked_url = Url.save_click_count(url)
    clicked_event = ClickedEvent.new(:clicked_url_id => clicked_url.id)
    clicked_event.save
    clicked_event
  end

  def self.graph_of_last_seven_days_hits(from)
    to = from + 6
    
    graph = OpenStruct.new()
    graph.title = Settings.stats_hits_per_day_title
    graph.no_data_message = Settings.stats_hits_per_day_no_data
    graph.minimum_value = 0

    # Gather click through data
    events = find(:all, :conditions => { :created_at => ((from - 1).to_time(:utc))..((to + 1).to_time(:utc)) }, :order => :created_at)
    events_grouped_by_date = events.group_by { |event| event.created_at.strftime("%Y-%m-%d") }
    
    graph.labels = []
    graph.data = [[Settings.stats_hits_per_day_clicked_count_text, []]]
    from.upto(to) do |date|
      date_s = date.strftime("%Y-%m-%d")
      if events_grouped_by_date.has_key?(date_s)
        graph.data[0][1] << events_grouped_by_date[date_s].length
      else
        graph.data[0][1] << 0
      end
      graph.labels << [graph.labels.length, date.strftime("%a")]
    end
    
    # Gather search events data
    events = SearchEvent.find(:all, :conditions => { :created_at => ((from - 1).to_time(:utc))..((to + 1).to_time(:utc)) }, :order => :created_at)
    events_grouped_by_date = events.group_by { |event| event.created_at.strftime("%Y-%m-%d") }

    graph.data << [Settings.stats_hits_per_day_search_count_text, []]
    from.upto(to) do |date|
      date_s = date.strftime("%Y-%m-%d")
      if events_grouped_by_date.has_key?(date_s)
        graph.data[1][1] << events_grouped_by_date[date_s].length
      else
        graph.data[1][1] << 0
      end
    end

    graph
  end

end

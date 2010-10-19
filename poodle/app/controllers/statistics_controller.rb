class StatisticsController < ApplicationController
    def index
      @search_term = params[:search_term]
      @start_index = params[:start_index]
      @graph = ClickedEvent.graph_of_last_seven_days_hits(Date.today - 6.days)
    end
end

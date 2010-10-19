class HelpController < ApplicationController
    def index
      @search_term = params[:search_term]
      @start_index = params[:start_index]
    end
end

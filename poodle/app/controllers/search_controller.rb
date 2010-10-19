class SearchController < ApplicationController

    # OpenSearch is by post at present, since it isn't going through a live session
    # I'm disabling rails authentication logic for this controller - Seeing as the
    # search tool cannot destroy any data I'm not bothered.
    skip_before_filter :verify_authenticity_token

    require 'solr'
    require 'uri'

    def index
        @time = 0
        begin
            @search_term = params[:search_term]

            query_start_index = params[:start_index] || params[:back_index] || params[:next_index]

            if @search_term and not query_start_index
                unless @search_term.empty?
                    query_start_index = params[:start_index] || 0
                    SearchEvent.new().save
                end
            end

            if query_start_index and @search_term
                begin
                    @results, @time = query(@search_term, query_start_index.to_i, Settings.search_results_per_page)
                    @start_index = query_start_index.to_i
                    @back_index, @next_index = indexes(query_start_index.to_i, @results.length, Settings.search_results_per_page)
                rescue RuntimeError
                    @search_term = nil
                    logger.error "Failed querying Solr at #{Settings.solr_url}"
                    flash.now[:notice] = Settings.solr_fail
                end
            end
        end
    end

    def search_result_clicked
        ClickedEvent.new_for(URI.unescape(params[:url])) if params[:url]
        render :nothing => true, :layout => false
    end

    def browser_settings_error
        logger.error "Browser had JavaScript disabled"
        flash.now[:notice] = Settings.browser_fail
        @stop_check_browser = false
    end

private

    def indexes(query_start_index, number_of_results, search_results_per_page)
        back_index = next_index = nil
        back_index = query_start_index - search_results_per_page if query_start_index >= search_results_per_page
        next_index = query_start_index + search_results_per_page if number_of_results == search_results_per_page
        [back_index, next_index]
    end

    def query(term, start_index, max_hits)
        started_query_at = Time.now
        results = Solr.find(term, Settings.solr_url, start_index, max_hits)
        time_taken = Time.now - started_query_at
        [results, time_taken < 0.01 ? 0.0 : time_taken]
    end

end

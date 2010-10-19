class OpenSearchController < ApplicationController
  def provider
    site = URI.parse('http://' + request.host + ':' + request.port.to_s)
    @title = Settings.title
    @description = Settings.description
    @host = site.to_s
    @icon_path = URI.join(site.to_s, Settings.icon)
    render "provider.xml.builder"
  end
end

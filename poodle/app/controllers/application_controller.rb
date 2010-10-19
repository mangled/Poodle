class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter do |controller|
    @revision = Settings.revision
    site = URI.parse('http://' + request.host + ':' + request.port.to_s)
    @provider = URI.join(site.to_s, 'provider.xml')
    @name = Settings.title
  end

end

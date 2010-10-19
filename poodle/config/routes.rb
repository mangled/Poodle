# I clearly have no idea of routes under rails 3.0! This works but looks messy!
Poodle::Application.routes.draw do
  get "search/index"
  post "search/index"
  post "search/search_result_clicked"
  get "search/browser_settings_error"
  get "help/index"
  get "statistics/index"

  root :to => "search#index"
  match "provider.xml" => "open_search#provider"
end

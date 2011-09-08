SteamRails::Application.routes.draw do
  root :to => 'main#index'
  
  # OmniAuth routes
  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "sessions#error"
  match "/signout" => "sessions#destroy", :as => :signout

  # Catch all for user/game achievement URL
  match '/a/:user/:game' => 'achievements#show'
end
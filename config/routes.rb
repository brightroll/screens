HaxAirplayWall::Application.routes.draw do

  root :to => 'welcome#index'

  resources :devices do
    collection do
      get 'browse'
    end
  end

  resources :slideshows

  resources :slides

  resources :auth do
    collection do
      get 'login'
      get 'logout'
      get 'finish'
    end
  end

end

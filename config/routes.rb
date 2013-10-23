Screens::Application.routes.draw do

  root :to => 'welcome#index'

  resources :devices do
    collection do
      get 'browse'
      get 'power'
    end
    member do
      post 'signal'
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

  mount Ckeditor::Engine => '/ckeditor'

  mount Rack::Directory.new(::File.join(Rails.root, 'public', 'files')) => '/files'

end

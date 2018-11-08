# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
#--
# rubocop:disable Metrics/LineLength
#++

Rails.application.routes.draw do

  # Add routes from the Blacklight gem config/routes.rb.
  mount Blacklight::Engine => '/'

  # NOTE: Blacklight 7 removed saved searches...
  resources :saved_search, only: [:index], controller: 'saved_searches', as: 'saved_searches', path: '/saved_searches' do
    collection do
      delete 'clear'
    end
    member do
      put    'save',   to: 'saved_searches#save',   as: 'save'
      delete 'forget', to: 'saved_searches#forget', as: 'forget'
      post   'forget', to: 'saved_searches#forget'
    end
  end

  # Add routes from the BlacklightAdvancedSearch gem config/routes.rb.
  mount BlacklightAdvancedSearch::Engine => '/'

  # Add routes for each search lens as defined in the override of:
  # @see Blacklight::Marc::Routes::RouteSets#catalog
  Blacklight::Marc.add_routes(self)

  # Add routes for each search lens.
  # @see Blacklight::Lens::Routes::RouteSets#
  Blacklight::Lens.add_routes(self)

  Blacklight::Lens::lens_keys.each do |lens|
    get "#{lens}/advanced", to: "#{lens}_advanced#index", controller: "#{lens}_advanced"
    #ctrlr = "#{lens}_advanced"
    #resource ctrlr, only: [:index], controller: "#{lens}_advanced"
  end

  # ===========================================================================
  # :section: Routing concern definitions
  # ===========================================================================

  # When invoked from a resource, this concern adds routes as defined in:
  # @see Blacklight::Routes::Searchable#call
  concern :searchable, Blacklight::Routes::Searchable.new

  # When invoked from a resource, this concern adds routes as defined in:
  # @see Blacklight::Routes::Exportable#call
  concern :exportable, Blacklight::Routes::Exportable.new

  # ===========================================================================
  # :section: Catalog lens routes
  # ===========================================================================

  resource :catalog, only: [:index], controller: 'catalog' do
    concerns :searchable
    concerns :exportable
  end

  get '/catalog/:id', to: 'catalog#show', as: 'catalog'

  # ===========================================================================
  # :section: Video lens routes
  # ===========================================================================

  resource :video, only: [:index], controller: 'video' do
    concerns :searchable
    concerns :exportable
  end

  get '/video/:id', to: 'video#show', as: 'video'

  # ===========================================================================
  # :section: Music lens routes
  # ===========================================================================

  resource :music, only: [:index], controller: 'music' do
    concerns :searchable
    concerns :exportable
  end

  get '/music/:id', to: 'music#show', as: 'music'

  # ===========================================================================
  # :section: Articles lens routes
  # ===========================================================================

  resource :articles, only: [:index], controller: 'articles' do
    concerns :searchable
    concerns :exportable
  end

  get '/articles/:id', to: 'articles#show', as: 'articles'

  # ===========================================================================
  # :section: Bookmarks
  # ===========================================================================

  resources :bookmarks do
    collection do
      delete 'clear'
    end
    concerns :exportable
  end

  # ===========================================================================
  # :section: User account
  # ===========================================================================

  get 'account', to: 'account#index'

  resource :account, only: [], controller: 'account' do
    get 'signed_out'
  end

  devise_for :users, path: '/account', path_names: {
    sign_in:  'login',
    sign_out: 'logout',
    edit:     'status' # TODO: use case?
  }

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  root to: 'catalog#index'

end

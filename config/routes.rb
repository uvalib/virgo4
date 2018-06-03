# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
#--
# rubocop:disable Metrics/LineLength
#++

Rails.application.routes.draw do

  # Add routes from the Blacklight gem config/routes.rb:
  #
  #   get    'search_history'
  #   delete 'search_history/clear'
  #   delete 'saved_searches/clear'
  #   get    'saved_searches'
  #   put    'saved_searches/save/:id'
  #   delete 'saved_searches/forget/:id'
  #   post   'saved_searches/forget/:id'
  #   post   '/catalog/:id/track'
  #   resources :suggest, only: :index, defaults: { format: 'json' }
  #
  mount Blacklight::Engine => '/'

  # Add routes from the BlacklightAdvancedSearch gem config/routes.rb:
  #
  #   get 'advanced'
  #
  mount BlacklightAdvancedSearch::Engine => '/'

  # Add routes for each search lens as defined in the override of:
  # @see Blacklight::Marc::Routes::RouteSets#catalog
  #
  #   get 'LENS/:id/librarian_view'
  #   get 'LENS/:id/endnote'
  #
  Blacklight::Marc.add_routes(self)

  # Add routes for each search lens:
  #
  #   get 'LENS/home',       to: redirect('/LENS')
  #   get 'LENS/index',      to: redirect('/LENS?q=*'), as: ':lens_all'
  #   get 'LENS/show',       to: 'LENS#show'
  #   get 'LENS/advanced',   to: ':lens_advanced#index', as: ':lens_advanced_search'
  #   get 'LENS/opensearch', to: 'LENS#opensearch'
  #
  Blacklight::Lens.add_routes(self)

  # ===========================================================================
  # :section: Routing concern definitions.
  # ===========================================================================

  # When invoked from a resource, this concern adds routes as defined in:
  # @see Blacklight::Routes::Searchable#call
  concern :searchable, Blacklight::Routes::Searchable.new

  # When invoked from a resource, this concern adds routes as defined in:
  # @see Blacklight::Routes::Exportable#call
  concern :exportable, Blacklight::Routes::Exportable.new

  # ===========================================================================
  # :section: Catalog lens routes.
  # ===========================================================================

  # Route for /catalog/suggest.
  resources 'suggest', only: [:index], as: 'catalog_suggest', path: 'catalog/suggest', defaults: { format: 'json' }

  # Routes for /catalog/email, /catalog/sms, and /catalog/citation.
  resources 'solr_documents', only: [:show], path: 'catalog', controller: 'catalog' do
    concerns :exportable
  end

  # Routes for /catalog, /catalog/:id/track, /catalog/opensearch, and
  # /catalog/facet/:id.
  resource 'catalog', only: [:index], as: 'catalog', path: 'catalog', controller: 'catalog' do
    concerns :searchable
  end

  # ===========================================================================
  # :section: Video lens routes.
  # ===========================================================================

  # Route for /video/suggest.
  resources 'video_suggest', only: [:index], as: 'video_suggest', path: 'video/suggest', defaults: { format: 'json' }

  # Routes for /video/email, /video/sms, and /video/citation.
  resources 'solr_documents', only: [:show], path: 'video', controller: 'video' do
    concerns :exportable
  end

  # Routes for /video, /video/:id/track, /video/opensearch, and
  # /video/facet/:id.
  resource 'video', only: [:index], as: 'video', path: 'video', controller: 'video' do
    concerns :searchable
  end

  # ===========================================================================
  # :section: Music lens routes.
  # ===========================================================================

  # Route for /music/suggest.
  resources 'music_suggest', only: [:index], as: 'music_suggest', path: 'music/suggest', defaults: { format: 'json' }

  # Routes for /music/email, /music/sms, and /music/citation.
  resources 'solr_documents', only: [:show], path: 'music', controller: 'music' do
    concerns :exportable
  end

  # Routes for /music, /music/:id/track, /music/opensearch, and
  # /music/facet/:id.
  resource 'music', only: [:index], as: 'music', path: 'music', controller: 'music' do
    concerns :searchable
  end

  # ===========================================================================
  # :section: Articles lens routes
  # ===========================================================================

  # Route for /articles/suggest.
  resources 'articles_suggest', only: [:index], as: 'articles_suggest', path: 'articles/suggest', defaults: { format: 'json' }

  # Routes for /articles/email, /articles/sms, and /articles/citation.
  resources 'eds_documents', only: [:show], path: 'articles', controller: 'articles' do
    concerns :exportable
  end

  # Routes for /articles, /articles/:id/track, /articles/opensearch, and
  # /articles/facet/:id.
  resource 'articles', only: [:index], as: 'articles', path: 'articles', controller: 'articles' do
    concerns :searchable
    member do # TODO: needed?
      get ':type/fulltext', action: 'fulltext', as: 'fulltext_link'
    end
  end

  # ===========================================================================
  # :section: Bookmarks
  # ===========================================================================

  resources 'bookmarks' do
    collection do
      delete 'clear'
    end
    concerns :exportable
  end

  # ===========================================================================
  # :section: User account
  # ===========================================================================

  #resource 'account', only: [], as: 'account', path: 'account', controller: 'account' do
  resource 'account', only: [], controller: 'account' do
    get 'index', to: 'account#index', as: '/account'
    get 'signed_out'
  end

  devise_for :users, path: 'account', path_names: {
    sign_in:  'login',
    sign_out: 'logout',
    edit:     'status' # TODO: probably there isn't an "edit"...
  }

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  root to: 'catalog#index'

end

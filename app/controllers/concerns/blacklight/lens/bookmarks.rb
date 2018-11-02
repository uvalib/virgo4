# app/controllers/concerns/blacklight/lens/bookmarks.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# A replacement for Blacklight::Bookmarks.
#
# Note that while this is mostly restful routing, the #update and #destroy
# actions take :id as the document ID and NOT the ID of the actual Bookmark
# action.
#
# Compare with:
# @see Blacklight::Bookmarks
#
# == Implementation Notes
# This does not include Blacklight::Bookmarks to avoid executing its `included`
# block -- which means that it has to completely recreate the module.
#
module Blacklight::Lens::Bookmarks

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Bookmarks unless ONLY_FOR_DOCUMENTATION

  include Blacklight::TokenBasedUser
  include Blacklight::Lens::Controller

  included do |base|

    __included(base, 'Blacklight::Lens::Bookmarks')

    # =========================================================================
    # :section: Controller Blacklight configuration
    # =========================================================================

    self.blacklight_config =
    ::Config::Catalog.new.deep_copy(self).tap do |config|

      config.add_results_collection_tool(:clear_bookmarks_widget)
      # config.add_results_collection_tool(:citation) # TODO: bookmarks export
      # config.add_results_collection_tool(:email)    # TODO: bookmarks email

      config.show.document_actions.clear

      config.lens = Blacklight::OpenStructWithHashAccess.new(
        document_model:         LensDocument,
        document_factory:       Blacklight::Lens::DocumentFactory,
        response_model:         Blacklight::Lens::Response,
        repository_class:       Blacklight::Lens::Repository,
        search_builder_class:   ::SearchBuilder,
        facet_paginator_class:  Blacklight::Solr::FacetPaginator
      )

      # Class for sending and receiving requests from a search index.
      config.repository_class = config.lens.repository_class

      # Class for converting Blacklight's URL parameters into request
      # parameters for the search index via repository_class.
      config.search_builder_class = config.lens.search_builder_class

      # Model that maps search index responses to Blacklight responses.
      config.response_model = config.lens.response_model

      # Use unspecified document types.
      config.document_model = config.lens.document_model

      # Use the generic document factory.
      config.document_factory = config.lens.document_factory

      # Class for paginating long lists of facet fields.
      config.facet_paginator_class = config.lens.facet_paginator_class

      # Ensure Solr gets arguments from :data instead of :params.
      config.http_method = Blacklight::Engine.config.bookmarks_http_method

      Log.debug { "CONFIG for BookmarksController:\n#{config_inspect(config)}" }

    end

    # =========================================================================
    # :section: Class attributes
    # =========================================================================

    self.search_state_class   = Blacklight::Lens::SearchState
    self.search_service_class = Blacklight::Lens::SearchService

    # =========================================================================
    # :section: Controller filter actions
    # =========================================================================

    before_action :verify_user

  end

  # ===========================================================================
  # :section: Blacklight::Bookmarks replacements
  # ===========================================================================

  public

  # == GET /bookmarks
  # Get documents associated with bookmarks.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#index
  #
  def index
    table = bookmark_table
    @response, @document_list = action_documents(table)
    @document_list =
      ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
        @document_list,
        'The @document_list instance variable is now deprecated ' \
        'and will be removed in Blacklight 8.0'
      )
    respond_to do |format|
      format.html { render layout: 'blacklight' }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { @presenter = json_presenter(@response, table) }
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # == PUT   /bookmarks/:id[?lens=LENS][&more_info=true]
  # == PATCH /bookmarks/:id[?lens=LENS][&more_info=true]
  #
  # Where :id is the :document_id of the bookmark to create, and LENS is one of
  # Blacklight::Lens#lens_keys.
  #
  # If :more_info is true then JSON results will include details about the
  # operation.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#update
  #
  def update
    params[:method] = __method__
    create
  end

  # == POST /bookmarks?bookmarks=...[&more_info=true]
  # == POST /bookmarks?id=DOC_ID[&lens=LENS][&more_info=true]
  #
  # Where :bookmarks is an array of hashes specifying bookmarks to create, or
  # where DOC_ID is the :document_id of a single bookmark to create, and LENS
  # is one of Blacklight::Lens#lens_keys.
  #
  # If :more_info is true then JSON results will include details about the
  # operation.  In this case :method is used to determine the name for the
  # details hash, defaulting to :create.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#create
  #
  def create
    bookmarks =
      if params[:bookmarks]
        permit_bookmarks[:bookmarks]
      else
        bookmark_fields(params)
      end
    bookmarks = Array.wrap(bookmarks)
    requested = bookmarks.size
    found   = []
    created = []
    saved = @user.persisted? || (@user.save! rescue false)
    table = (@user.bookmarks if saved)
    if table
      bookmarks.each do |b|
        if table.where(b).exists?
          found   << b[:document_id]
        elsif table.create(b)
          created << b[:document_id]
        end
      end
    end
    count   = found.size + created.size
    success = (count == requested)
    if request.xhr?
      if success
        result = { bookmarks: { count: table.size } }
        if add_details?
          method = params[:method] || __method__
          result[:bookmarks][method] = {
            request:  bookmarks,
            found:    found,
            created:  created,
          }
        end
        render json: result
      else
        head 500
      end
    else
      if success
        go_back notice: t('blacklight.bookmarks.add.success', count: count)
      else
        go_back error:  t('blacklight.bookmarks.add.failure', count: count)
      end
    end
  end

  # == DELETE /bookmarks/:id
  #
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#destroy
  #
  def destroy
    bookmark = bookmark_criteria(params)
    table    = @user.bookmarks
    target   = table.find_by(bookmark)
    success  = target&.delete && target.destroyed?
    if request.xhr?
      if success
        result = { bookmarks: { count: table.size } }
        if add_details?
          method = params[:method] || __method__
          result[:bookmarks][method] = {
            request:  bookmark,
            found:    1,
            deleted:  1,
          }
        end
        render json: result
      else
        head 500
      end
    else
      if success
        go_back notice: t('blacklight.bookmarks.remove.success')
      else
        go_back error:  t('blacklight.bookmarks.remove.failure')
      end
    end
  end

  # == DELETE /bookmarks/clear
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#clear
  #
  def clear
    table   = @user.bookmarks
    total   = (table.size if add_details?)
    success = table.clear
    if request.xhr?
      if success
        result = { bookmarks: { count: table.size } }
        if add_details?
          method = params[:method] || __method__
          result[:bookmarks][method] = {
            found:    total,
            deleted:  success,
          }
        end
        render json: result
      else
        head 500
      end
    else
      if success
        flash[:notice] = t('blacklight.bookmarks.clear.success')
      else
        flash[:error]  = t('blacklight.bookmarks.clear.failure')
      end
      redirect_to action: 'index'
    end
  end

  # ===========================================================================
  # :section: Blacklight::Bookmarks replacements
  # ===========================================================================

  protected

  # Used by the method generated by #add_show_tools_partial to acquire the
  # items to be handled by the tool.
  #
  # @param [Array<Bookmark>, nil] table
  #
  # @return [Array<(Blacklight::Lens::Response, Array<Blacklight::Document>)>]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#action_documents
  #
  def action_documents(table = nil)
    ids = bookmark_ids(table)
    search_service(nil, request).fetch(ids)
  end

  # Used by the method generated by #add_show_tools_partial as the path to
  # redirect to after a POST to the tool route.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#action_success_redirect_path
  #
  def action_success_redirect_path
    bookmarks_path
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box.
  #
  # @param [Hash] options
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#search_action_url
  #
  # TODO: In this case the search should be for combined results.
  #
  def search_action_url(options = {})
    opt = { controller: current_lens_key, action: 'index' }
    opt.reverse_merge!(options) if options.is_a?(Hash)
    url_for(opt)
  end

  # ===========================================================================
  # :section: Filter actions - Blacklight::Bookmarks replacements
  # ===========================================================================

  protected

  # Called before each action to ensure that bookmark operations are limited to
  # logged in users.
  #
  # @raise [Blacklight::Exceptions::AccessDenied]  If the session is anonymous.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#verify_user
  #
  def verify_user
    return if (@user = current_or_guest_user)
    return if (action == 'index') && token_or_current_or_guest_user
    flash[:notice] = t('blacklight.bookmarks.need_login')
    raise Blacklight::Exceptions::AccessDenied
  end

  # ===========================================================================
  # :section: Blacklight::Bookmarks replacements
  # ===========================================================================

  private

  # No bookmarks action causes a new search.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#start_new_search_session?
  #
  # == Implementation Notes
  # This differs from the original method.
  #
  def start_new_search_session?
    false
  end

  # permit_bookmarks
  #
  # @return [Hash]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#permit_bookmarks
  #
  def permit_bookmarks
    params.permit(bookmarks: [:document_id, :document_type, :lens])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The currently-bookmarked items from the database.
  #
  # @return [Array<Bookmark>]
  #
  def bookmark_table
    user = @user || token_or_current_or_guest_user
    @bookmarks ||= user&.bookmarks || []
  end

  # The list of document IDs of the currently-bookmarked items.  Each entry is
  # the identifier of the item optionally followed by a slash and the name of
  # the item's lens.
  #
  # @param [Array<Bookmark>] table
  #
  # @return [Array<String>]
  #
  def bookmark_ids(table = nil)
    (table || bookmark_table).map do |bookmark|
      [bookmark.document_id, bookmark.lens].reject(&:blank?).join('/')
    end
  end

  # Creates the @presenter used in
  # `app/views/bookmarks/index.json.jbuilder`.
  #
  # @param [Blacklight::Lens::Response]  response
  # @param [Array<Bookmark>, nil]        bookmarks
  #
  # @return [Blacklight::Lens::JsonPresenter]
  #
  def json_presenter(response = nil, bookmarks = nil)
    response  ||= @response
    bookmarks ||= bookmark_table
    Blacklight::Lens::JsonPresenter.new(response, bookmarks)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # A hash which specifies a bookmark for lookup in the 'bookmarks' table.
  #
  # @param [String, nil] id
  # @param [Hash]        opt
  #
  # @option opt [String] :id
  # @option opt [Symbol] :lens
  # @option opt [Class]  :type
  #
  # @return [Hash]
  #
  def bookmark_criteria(id = nil, opt = nil)
    bookmark_fields(id, opt).except(:lens)
  end

  # A hash which specifies the data fields of a bookmark.
  #
  # @param [String, nil]                             id
  # @param [ActionController::Parameters, Hash, nil] opt
  #
  # @option opt [String] :id
  # @option opt [Symbol] :lens
  # @option opt [Class]  :type
  #
  # @return [Hash]
  #
  def bookmark_fields(id = nil, opt = nil)
    id = id.to_unsafe_h if id.is_a?(ActionController::Parameters)
    if id.is_a?(Hash)
      opt = id
      id  = nil
    end
    opt ||= {}
    id  ||= opt[:id]
    lens  = opt[:lens].to_s.to_sym.presence || lens_key_for(id)
    type  = opt[:type] || ((lens == :articles) ? EdsDocument : SolrDocument)
    { document_id: id.to_s, document_type: type.to_s, lens: lens.to_s }
  end

  # Check for a request for more details in the URL parameters.
  #
  # @param [ActionController::Parameters, Hash, nil] p    Default: `params`
  #
  def add_details?(p = nil)
    p ||= params
    more_info = p[:more_info].to_s.downcase
    more_info.present? && %w(true yes on).any? { |v| details == v }
  end

end

__loading_end(__FILE__)

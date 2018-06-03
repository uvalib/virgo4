# app/controllers/concerns/blacklight/bookmarks_ext.rb
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
# TODO: If this is going to copy config from Catalog anyway then this module
# *could* just extend Blacklight::Bookmarks although most methods are
# overridden...
#
module Blacklight::BookmarksExt

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Bookmarks unless ONLY_FOR_DOCUMENTATION

  include Blacklight::BaseExt
  include Blacklight::DefaultComponentConfiguration
  include Blacklight::Facet

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::BookmarksExt')

    include Blacklight::SearchHelperExt
    include Blacklight::TokenBasedUser

    include RescueConcern
    include ExportConcern
    include MailConcern
    include SearchConcern
    include LensConcern

    # =========================================================================
    # :section: Controller Blacklight configuration
    # =========================================================================

    copy_blacklight_config_from(CatalogController).tap do |config|

      config.add_results_collection_tool(:clear_bookmarks_widget)
      config.add_results_collection_tool(:citation) # TODO: bookmarks export

      # Ensure Solr gets arguments from :data instead of :params.
      config.http_method = Blacklight::Engine.config.bookmarks_http_method

      Log.debug { "CONFIGURATION for #{base}:\n#{config_inspect(config)}" }

    end

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
    @response, @document_list = fetch(bookmark_ids(table))
    respond_to do |format|
      format.html { }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { @presenter = json_presenter(@response, table) }
      additional_response_formats(format)
=begin # TODO: export formats for bookmarks
      document_export_formats(format)
=end
    end
  end

  # == PUT   /bookmarks/:id[?lens=LENS][&more_info=true]
  # == PATCH /bookmarks/:id[?lens=LENS][&more_info=true]
  #
  # Where :id is the :document_id of the bookmark to create, and LENS is one of
  # Blacklight::Lens#keys.
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
  # is one of Blacklight::Lens#keys.
  #
  # If :more_info is true then JSON results will include details about the
  # operation.  In this case :method is used to determine the name for the
  # details hash, defaulting to :create.
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#create
  #
  def create
    bookmarks = params[:bookmarks] || [bookmark_fields(params.to_unsafe_h)]
    requested = bookmarks.size
    found   = []
    created = []
    saved = @user.persisted? || (@user.save! rescue false)
    table = (@user.bookmarks if saved)
    if table
      bookmarks.each do |b|
        if table.where(b).exists?
          found   << b.document_id
        elsif table.create(b)
          created << b.document_id
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
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method replaces:
  # @see Blacklight::Bookmarks#action_documents
  #
  def action_documents
    fetch(bookmark_ids)
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
    search_catalog_url(options.except(:controller, :action))
  end

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
  # :section:
  # ===========================================================================

  protected

  # The currently-bookmarked items from the database.
  #
  # @return [Array<Bookmark>]
  #
  def bookmark_table
    user = @user || token_or_current_or_guest_user
    @table ||= user&.bookmarks || []
  end

  # The list of document IDs of the currently-bookmarked items.
  #
  # @param [Array<Bookmark>] table
  #
  # @return [Array<String>]
  #
  def bookmark_ids(table = nil)
    (table || bookmark_table).map { |b| b.document_id.to_s }
  end

  # Creates the @presenter used in
  # `app/views/bookmarks/index.json.jbuilder`.
  #
  # @param [Blacklight::Solr::Response]  response
  # @param [Array<Bookmark>, nil]        bookmarks
  #
  # @return [Blacklight::JsonPresenterExt]
  #
  def json_presenter(response = nil, bookmarks = nil)
    response  ||= @response
    bookmarks ||= bookmark_table
    Blacklight::JsonPresenterExt.new(response, bookmarks)
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
    bookmark_fields(id, opt).except(:search_lens)
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
    lens  = opt[:lens].to_s.to_sym.presence || Blacklight::Lens.key_for_doc(id)
    type  = opt[:type] || ((lens == :articles) ? EdsDocument : SolrDocument)
    { document_id: id.to_s, document_type: type.to_s, search_lens: lens.to_s }
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

  # TODO: testing...
  def sms_mappings
    Blacklight::Engine.config.sms_mappings
  end

end

__loading_end(__FILE__)

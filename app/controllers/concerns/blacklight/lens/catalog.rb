# app/controllers/concerns/blacklight/lens/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::Catalog
#
module Blacklight::Lens::Catalog

  extend ActiveSupport::Concern

  include Blacklight::Catalog
  include Blacklight::Lens::Controller

  included do |base|

    __included(base, 'Blacklight::Lens::Catalog')

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :has_query? if respond_to?(:helper_method)

    helper Blacklight::Lens::Facet if respond_to?(:helper)

  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  public

  # == GET /catalog
  # Get search results from the index service.
  #
  # This method overrides:
  # @see Blacklight::Catalog#index
  #
  def index
    @response, @document_list = search_service.search_results
    @document_list =
      ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
        @document_list,
        'The @document_list instance variable is deprecated; ' \
        'use @response.documents instead.'
      )
    respond_to do |format|
      format.html { store_preferred_view }
      format.rss  { render layout: false }
      format.atom { render layout: false }
      format.json { @presenter = json_presenter(@response) }
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # == GET /catalog/:id
  # == GET /:lens/:id
  # Get a single document from the index.
  #
  # == GET /catalog/:id.:format
  # == GET /:lens/:id.:format
  # Render a single document in the given format (this includes export formats
  # like :ris for Zotero, :endnote for EndNote, etc).
  #
  # This method overrides:
  # @see Blacklight::Catalog#show
  #
  def show
    super
  end

  # == GET /catalog/raw/:id
  # == GET /:lens/raw/:id
  # Get a single document from the index in JSON format.
  #
  # This method overrides:
  # @see Blacklight::Catalog#raw
  #
  def raw
    super
  end

  # == POST /catalog/:id/track
  # == POST /:lens/:id/track
  # Updates the search counter (allows the show view to paginate).
  #
  # This method overrides:
  # @see Blacklight::Catalog#track
  #
  def track
    super
  end

  # == GET /catalog/facet/:id
  # == GET /:lens/facet/:id
  # Displays values and pagination links for a single facet field.
  #
  # This method overrides:
  # @see Blacklight::Catalog#facet
  #
  def facet
    super
  end

  # == GET /catalog/opensearch
  # == GET /:lens/opensearch
  # Method to serve up XML OpenSearch description and JSON autocomplete
  # response.
  #
  # This method overrides:
  # @see Blacklight::Catalog#opensearch
  #
  def opensearch
    super
  end

  # == GET /catalog/suggest
  # == GET /:lens/suggest
  #
  # This method replaces:
  # @see Blacklight::Catalog#suggest
  #
  def suggest
    respond_to do |format|
      format.json { render json: suggestions_service.suggestions }
    end
  end

  # ===========================================================================
  # :section: Fall-back tool actions
  #
  # Certain show tools defined in Config::Base#add_tools! cause methods to be
  # inserted into the controller via ActionBuilder.  Tools that include the
  # `define_method: false` option must be defined manually here.
  #
  # @see Config::Base#add_tools!
  # @see Blacklight::ActionBuilder#build
  # ===========================================================================

  public

  # == GET /catalog/citation
  # == GET /:lens/citation
  #
  def citation
    @response, @document = search_service.fetch(params[:id])
    respond_to do |format|
      format.html { render layout: false }
    end
  end #unless defined?(:citation)

  # == GET /catalog/email?id=DOC_ID
  # == GET /:lens/email?id=DOC_ID
  # == POST /catalog/email?id=DOC_ID
  # == POST /:lens/email?id=DOC_ID
  #
  def email
    @response, @document = search_service.fetch(params[:id])
    if request.post? && email_action(@document)
      flash[:success] = t('blacklight.email.success')
      render 'email_success'
    elsif request.get?
      flash.clear
    end
  end unless defined?(:email)

  # == GET /catalog/sms
  # == GET /:lens/sms
  # == POST /catalog/sms?id=DOC_ID
  # == POST /:lens/sms?id=DOC_ID
  #
  def sms
    @response, @document = search_service.fetch(params[:id])
    if request.post? && sms_action(@document)
      flash[:success] = t('blacklight.sms.success')
      render 'sms_success'
    elsif request.get?
      flash.clear
    end
  end unless defined?(:sms)

  # ===========================================================================
  # :section: Fall-back tool actions
  #
  # NOTE: These repeated definitions shouldn't be necessary...
  # @see ExportConcern#librarian_view etc
  # ===========================================================================

  public

  # == GET /:lens/:id/librarian_view
  # == GET /:lens/librarian_view?id=:id
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#librarian_view
  #
  def librarian_view
    @response, @document = search_service.fetch(params[:id])
    respond_to do |format|
      format.html { render layout: false }
      format.json
    end
  end

=begin # TODO: remove?
  # == GET /:lens/refworks?id=:id
  #
  def refworks
    @response, @documents = search_service.fetch(params[:id])
    respond_to do |format|
      format.refworks_marc_txt { render layout: false }
    end
  end
=end

=begin # TODO: remove?
  # == GET /:lens/endnote?id=:id
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#endnote
  #
  def endnote
    @response, @documents = search_service.fetch(params[:id])
    respond_to do |format|
      format.endnote { render layout: false }
    end
  end
=end

=begin # TODO: remove?
  # == GET /:lens/zotero?id=:id
  #
  def zotero
    @response, @documents = search_service.fetch(params[:id])
    respond_to do |format|
      format.ris { render layout: false }
    end
  end
=end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  protected

  # @return [Array] first value is a Blacklight::Solr::Response and the second
  #                 is a list of documents
  def action_documents
    search_service.fetch(Array(params[:id]))
  end

  # suggestions_service
  #
  # @return [Blacklight::Suggest::Response]
  #
  # This method overrides:
  # @see Blacklight::Catalog#suggestions_service
  #
  def suggestions_service
    repository = search_service.repository
    Blacklight::Lens::SuggestSearch.new(params, repository).suggestions
  end

  # Used by the method generated by #add_show_tools_partial as the path to
  # redirect to after a POST to the tool route.
  #
  # This method overrides:
  # @see Blacklight::Catalog#action_success_redirect_path
  #
  def action_success_redirect_path
    params.slice(:controller, :action, :id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether there has been a query issued by the user.
  #
  def has_query?
    params[:q].present? && (params[:q] != '*')
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # non-routable methods ->
  # ===========================================================================

  protected

  # Overrides the Blacklight::Controller provided #search_action_url.
  #
  # By default, any search action from a Blacklight::Catalog controller should
  # use the current controller when constructing the route.
  #
  # @param [Hash] options
  #
  # @option options [Symbol]  :lens       Specify the controlling lens; default
  #                                         is `current_lens_key`.
  #
  # @option options [Boolean] :canonical  If *true* return the path for the
  #                                         canonical controller related to
  #                                         the current controller or to :lens.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Catalog#search_action_url
  #
  # TODO: super is not Blacklight::Lens::Controller#search_action_url
  # @see AdvancedSearchConcern#search_action_url
  # @see Blacklight::Lens::Controller#search_action_url
  # @see Blacklight::Lens::Bookmarks#search_action_url
  #
  def search_action_url(options = nil)
    opt = (options || {}).merge(action: 'index')
    lens = opt.delete(:lens) || current_lens_key
    canonical = opt.delete(:canonical)
    canonical &&= Blacklight::Lens.canonical_for(lens)
    opt[:controller] = canonical || lens
    url_for(opt)
  end

end

__loading_end(__FILE__)

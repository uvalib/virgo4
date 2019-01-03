# app/controllers/concerns/export_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Rolls-up logic associated with bibliographic citation exports and also
# "librarian view".
#
# @see Blacklight::Marc::Catalog
#
module ExportConcern

  extend ActiveSupport::Concern

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Lens::Catalog unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Marc::Catalog unless ONLY_FOR_DOCUMENTATION

  include BlacklightHelper
  include ExportHelper

  included do |base|
    __included(base, 'ExportConcern')
  end

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog replacements
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

  # Render additional response formats for the index action, as provided by the
  # blacklight configuration
  #
  # @param [Hash] format
  #
  # @return [void]
  #
  # @raise [ActionController::RoutingError]
  #
  # @note Make sure your format has a well known mime-type or is registered in
  # config/initializers/mime_types.rb
  #
  # @example
  #   config.index.respond_to.txt = Proc.new { render plain: 'A list of docs' }
  #
  # Compare with:
  # @see Blacklight::Catalog#additional_response_formats
  #
  def additional_response_formats(format)
    blacklight_config.index.respond_to.each do |key, config|
      format.send(key) do
        case config
          when false  then raise ActionController::RoutingError, 'Not Found'
          when Hash   then render config
          when Proc   then instance_exec(&config)
          when Symbol then send config
          when String then send config
          else             render({})
        end
      end
    end
  end

  # Render the document export formats for a response.
  #
  # First, try to render an appropriate template (e.g. index.endnote.erb)
  # If that fails, just concatenate the document export responses with a
  # newline.
  #
  # @param [Symbol, String] fmt_name
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # Compare with:
  # @see Blacklight::Catalog#render_document_export_format
  #
  def render_document_export_format(fmt_name)
    render
  rescue => e
    unless e.is_a?(ActionView::MissingTemplate)
      Log.error(__method__, e, 'UNEXPECTED')
    end
    docs    = @response&.documents || []
    exports = docs.map { |x| x.export_as(fmt_name) if x.exports_as?(fmt_name) }
    render plain: exports.compact.join("\n"), layout: false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Creates the @presenter used in "catalog/{index,show}.json.jbuilder".
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] docs
  # @param [Symbol] view              Optional.
  #
  # @return [Blacklight::Lens::JsonPresenter]
  #
  # This method overrides:
  # @see BlacklightHelper#json_presenter
  #
  def json_presenter(docs, view: nil)
    view  ||= docs.is_a?(Array) ? :index : :show
    facets  = (facets_from_request if view == :index)
    context = self
    json_presenter_class(context).new(docs, facets, context, view: view)
  end

end

__loading_end(__FILE__)

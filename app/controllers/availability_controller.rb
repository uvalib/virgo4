# app/controllers/availability_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Supports asynchronous acquisition of availability information.
#
class AvailabilityController < ApplicationController

  include SearchConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /availability?id=:id[,:id,...]
  # Get "brief availability" information for one or more index items.
  #
  def index
    @document_list = documents(id_params)
    respond_to do |format|
      format.html { render layout: false }
      format.json # @see app/views/availability/index.json.jbuilder
      format.xml  # @see app/views/availability/index.xml.builder
    end
  end

  # == GET /availability/:id
  # Get availability information for an item.
  #
  def show
    @document = documents(id_params.first)
    respond_to do |format|
      format.html { render layout: false }
      format.json # @see app/views/availability/show.json.jbuilder
      format.xml  # @see app/views/availability/show.xml.builder
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Get ID(s) from URL parameters.
  #
  # @return [Array<String>]
  #
  def id_params
    ids = params[:id]
    ids = ids.join(',') if ids.is_a?(Array)
    ids.to_s.split(/\s*,\s*/)
  end

  # Get Solr document(s) by document ID.
  #
  # @param [String, Array<String>] ids
  #
  # @return [Array<SolrDocument>]     If *ids* is an array.
  # @return [SolrDocument, nil]       Otherwise.
  #
  def documents(ids)
    _, document = search_service.fetch(ids)
    document
  end

end

__loading_end(__FILE__)

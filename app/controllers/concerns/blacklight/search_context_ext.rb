# app/controllers/concerns/blacklight/search_context_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::SearchContextExt

  extend ActiveSupport::Concern

  include Blacklight::SearchContext

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::SearchContextExt')

    include LensConcern

  end

  # ===========================================================================
  # :section: Blacklight::SearchContext overrides
  # ===========================================================================

  protected

  # find_search_session
  #
  # @return [Search, nil]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#find_search_session
  #
  def find_search_session
    if agent_is_crawler?
      nil
    elsif (context = params[:search_context]).present?
      find_or_initialize_search_session_from_params(JSON.parse(context))
    elsif (sid = params[:search_id]).present?
      # TODO: check the search id signature.
      searches_from_history.find(sid)
    elsif start_new_search_session?
      find_or_initialize_search_session_from_params(search_state.to_h)
    elsif (sid = search_session['id']).present?
      searches_from_history.find(sid)
    end
  rescue ActiveRecord::RecordNotFound => e
    Log.debug(__method__, e)
  rescue => e
    Log.error(__method__, e, 'UNEXPECTED')
  end

  # Used in the show action for single view pagination to set up
  # @previous_document and @next_document.
  #
  # @return [void]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#setup_next_and_previous_documents
  #
  def setup_next_and_previous_documents
    counter = search_session['counter']
    search  = current_search_session
    return unless counter && search
    index          = counter.to_i - 1
    query          = search.query_params.with_indifferent_access
    response, docs = get_previous_and_next_documents_for_search(index, query)
    search_session['total']  = response.total
    @search_context_response = response
    @previous_document       = docs.first
    @next_document           = docs.last
  rescue Blacklight::Exceptions::InvalidRequest => e
    Log.warn(__method__, e)
  rescue => e
    Log.error(__method__, e, 'UNEXPECTED')
  end

end

__loading_end(__FILE__)

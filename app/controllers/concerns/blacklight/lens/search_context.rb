# app/controllers/concerns/blacklight/lens/search_context.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::SearchContext
#
module Blacklight::Lens::SearchContext

  extend ActiveSupport::Concern

  include Blacklight::SearchContext

  included do |base|
    __included(base, 'Blacklight::Lens::SearchContext')
  end

  # A list of query parameters that should not be persisted for a search.
  #
  # @type [Array<Symbol>]
  #
  # @see self#blacklisted_search_session_params
  #
  PARAM_NOT_PERSISTED = %i(
    commit counter total search_id page per_page
    view
  ).freeze

  # A list of query parameters that are persisted as part of a search but do
  # not count towards determining whether the search is one that should be
  # persisted.
  #
  # @type [Array<Symbol>]
  #
  # @see self#blacklisted_search_session_params
  #
  PARAM_NOT_COUNTED = %i(action search_field)

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

  # find_or_initialize_search_session_from_params
  #
  # @param [Hash] params
  #
  # @return [Search]
  # @return [nil]                     If the search has no query or facets.
  #
  # This method overrides:
  # @see Blacklight::SearchContext#find_or_initialize_search_session_from_params
  #
  def find_or_initialize_search_session_from_params(params)
    search_param_count = 0
    null_search = (params[:q] == '*')
    params =
      params.map { |k, v|
        k = k.to_sym
        next if v.blank? || blacklisted_search_session_params.include?(k)
        does_not_count =
          case k
            when :controller
              v = (v == 'advanced') ? 'catalog' : v.sub(/_advanced$/, '')
            when :q
              null_search
            else
              PARAM_NOT_COUNTED.include?(k)
          end
        search_param_count += 1 unless does_not_count
        [k, v]
      }.compact.to_h.with_indifferent_access
    return if search_param_count.zero?

    searches_from_history.find { |x| x.query_params == params } ||
      Search.create(query_params: params).tap { |s| add_to_search_history(s) }
  end

  # Add a search to the in-session search history list.
  #
  # @param [Search] search
  #
  # @return [Array<Numeric>]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#add_to_search_history
  #
  def add_to_search_history(search)
    h = session[:history]
    h = h ? h.reject(&:blank?).unshift(search.id).uniq : [search.id]
    session[:history] = h.first(blacklight_config.search_history_window)
  end

  # A list of query parameters that should not be persisted for a search.
  #
  # @return [Array<Symbol>]
  #
  # @see self#PARAM_NOT_PERSISTED
  #
  # This method overrides:
  # @see Blacklight::SearchContext#blacklisted_search_session_params
  #
  def blacklisted_search_session_params
    PARAM_NOT_PERSISTED
  end

  # Used in the show action for single view pagination.
  #
  # @return [Hash{Symbol=>Blacklight::Document}]
  # @return [Hash{Symbol=>nil}]
  #
  # This method overrides:
  # @see Blacklight::SearchContext#setup_next_and_previous_documents
  #
  def setup_next_and_previous_documents
    counter = search_session['counter']
    search  = current_search_session
    prev_doc, next_doc =
      if counter.present? && search.present?
        index = counter.to_i - 1
        #query = search.query_params.with_indifferent_access
        query = search_state.reset(search.query_params).to_hash
        response, docs =
          search_service.previous_and_next_documents_for_search(index, query)
        search_session['total'] = response.total
        [docs.first, docs.last]
      end
  rescue Blacklight::Exceptions::InvalidRequest => e
    Log.warn(__method__, e)
  rescue => e
    Log.error(__method__, e, 'UNEXPECTED')
  ensure
    return { prev: prev_doc, next: next_doc }
  end

end

__loading_end(__FILE__)

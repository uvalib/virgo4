# app/models/blacklight/eds/suggest_search_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative('../eds')
require 'blacklight/suggest_search'

module Blacklight::Eds

  # Blacklight::Eds::SuggestSearchEds
  #
  # Subclass of:
  # @see Blacklight::SuggestSearch
  #
  class SuggestSearchEds < Blacklight::SuggestSearch

    # TODO: share with Blacklight::Eds::Suggest::ResponseEds
    SUGGEST_FIELDS = {
      title:       %i(eds_title eds_other_titles),
      author:      %i(eds_authors),
      journal:     %i(eds_source_title eds_series),
      subject:     %i(eds_subjects),
      keyword:     %i(eds_author_supplied_keywords),
      isbn:        %i(eds_isbns),
      issn:        %i(eds_issns),
      call_number: nil,
      published:   %i(eds_publisher),
    }.stringify_keys.freeze

    # =========================================================================
    # :section: Blacklight::SuggestSearch overrides
    # =========================================================================

    public

    # Create a new self instance.
    #
    # @param [ActionController::Parameters, Hash] params
    # @param [Blacklight::Eds::Repository]        repository
    #
    # This method overrides:
    # @see Blacklight::SuggestSearch#initialize
    #
    def initialize(params, repository)
      @request_params =
        params.slice(:q, :guest, :session_token, :eds_session_token).tap do |p|
          if p[:eds_session_token]
            p[:session_token] = p.delete(:eds_session_token)
          end
        end
      sf = params[:search_field].to_s.presence
      sf = nil if sf && %w(advanced all_fields).include?(sf)
      @request_params[:search_field] = sf if sf
      fields = SUGGEST_FIELDS[sf].presence || SUGGEST_FIELDS.values.flatten
      @request_params[:fl]    = [:score, *fields].compact.uniq.join(',')
      @request_params[:facet] = 'false'
      @request_params[:rows]  = 25
      @repository = repository
    end

    # For now, only use the :q parameter to create a response.
    #
    # @return [Blacklight::Eds::Suggest::ResponseEds]
    #
    # This method overrides:
    # @see Blacklight::SuggestSearch#suggestions
    #
    def suggestions
      Blacklight::Eds::Suggest::ResponseEds.new(
        suggest_results,
        @request_params,
        suggest_handler_path
      )
    end

    # Query the suggest handler.
    #
    # @return [Blacklight::Eds::Response]
    #
    # This method overrides:
    # @see Blacklight::SuggestSearchEds#suggest_results
    #
    def suggest_results
      @repository.search(@request_params, debug: false)
    end

  end

end

__loading_end(__FILE__)

# app/models/concerns/blacklight/eds/suggest/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'sanitize'
require 'blacklight/eds'
require_relative '../../lens/suggest/response'

module Blacklight::Eds

  module Suggest

    # Blacklight::Eds::Suggest::Response
    #
    # @see Blacklight::Lens::Suggest::Response
    #
    class Response < Blacklight::Lens::Suggest::Response

      # TODO: share with Blacklight::Eds::SuggestSearch
      SUGGEST_FIELDS = {
        title:       %w(eds_title eds_other_titles),
        author:      %w(eds_authors),
        journal:     %w(eds_source_title eds_series),
        subject:     %w(eds_subjects),
        keyword:     %w(eds_author_supplied_keywords),
        isbn:        %w(eds_isbns),
        issn:        %w(eds_issns),
        call_number: nil,
        published:   %w(eds_publisher),
      }.stringify_keys.freeze

      # The number of suggestions to request for autosuggest.
      #
      # @type [Numeric]
      #
      # This should agree with:
      # @see app/assets/javascripts/blacklight/autocomplete.js
      #
      # TODO: share with Blacklight::Eds::Suggest::ResponseEds
      #
      SUGGESTION_COUNT = 7

      # =======================================================================
      # :section: Blacklight::Suggest::Response overrides
      # =======================================================================

      public

      # Extracts suggested terms from the suggester response.
      #
      # @return [Array<Hash{String=>String}>]
      #
      # This method overrides:
      # @see Blacklight::Suggest::Response#suggestions
      #
      # TODO: there is probably a better way to handle this through the EDS API
      #
      def suggestions
        query =
          request_params[:q].to_s.squish.downcase
            .sub(/^[^a-z0-9_]+/, '').sub(/[^a-z0-9_]+$/, '')
            .split(' ')
        docs   = response.dig('response', 'docs') || []
        search = request_params[:search_field].to_s
        fields = SUGGEST_FIELDS[search] || SUGGEST_FIELDS.values.flatten
        docs
          .map { |doc|
            # To prepare for sorting by descending order of usefulness,
            # transform each *doc* into an array with these elements:
            # [0] all_score - terms with all matches to the top
            # [1] any_score - terms with most matches to the top
            # [2] score     - tie-breaker sort by descending relevance
            # [3..-1]       - fields with terms
            terms =
              doc.slice(*fields).values.flatten.map { |term|
                Sanitize.fragment(term).downcase if term.is_a?(String)
              }.compact
            any = query.count { |qt| terms.any? { |term| term.include?(qt) } }
            next if any.zero?
            all = query.count { |qt| terms.all? { |term| term.include?(qt) } }
            terms.unshift(-doc[:eds_relevancy_score].to_f)
            terms.unshift(query.size - any)
            terms.unshift(query.size - all)
          }
          .compact
          .sort
          .map { |terms| terms.shift(3); terms } # Remove non-search-terms.
          .flatten
          .uniq
          .select { |term| query.any? { |qt| term.include?(qt) } }
          .sort_by { |t| query.size - query.count { |qt| t.include?(qt) } }
          .first(SUGGESTION_COUNT)
          .map { |term| { 'term' => term, 'weight' => 1, 'payload' => '' } }
      end

    end

  end

end

__loading_end(__FILE__)

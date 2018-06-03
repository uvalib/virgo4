# app/presenters/blacklight/json_presenter_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  class JsonPresenterExt < Blacklight::JsonPresenter

    # =========================================================================
    # :section: Blacklight::JsonPresenter overrides
    # =========================================================================

    public

    # Initialize an instance, accepting arguments as needed to pass to the
    # initializer of the superclass.
    #
    # @param [Array] args
    #
    # @option args [Solr::Response]
    # @option args [Blacklight::Configuration]
    # @option args [ActiveRecord::Associations::CollectionProxy]
    #
    # @option args.last [Boolean] :full   Show full details for each item
    # @option args.last [Boolean] :doc    Show document (for bookmarks);
    #                                       default: *true*.
    #
    def initialize(*args)
      @options = args.extract_options!
      @options[:doc] = true unless @options.key?(:doc)
      @item_list = response = docs = facets = config = nil
      facet_counts_type = Blacklight::Solr::Response::Facets::FacetField
      args.each do |v|
        case v
          when Solr::Response                     then response   = v
          when Blacklight::Configuration          then config     = v
          when Blacklight::Solr::Response::Facets then facets     = v
          when ActiveRecord::Relation             then @item_list = v
          else
            v = Array.wrap(v).compact
            next if v.blank?
            case v.first
              when Blacklight::Document                 then docs   = v
              when Blacklight::Facet, facet_counts_type then facets = v
              else
                error = "#{v.first.class} unexpected: #{v.inspect}"
                raise error unless Virgo.production?
                Log.warn("#{self.class}: #{error}")
            end
        end
      end
      @item_list ||= docs
      docs       ||= response&.documents
      facets     ||= response&.dig(:facet_counts, :facet_fields) || {}
      config     ||= blacklight_config
      super(response, docs, facets, config)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Options for searches and bookmarks.
    #
    # @return [Hash]
    #
    attr_reader :options

    # For all types, this is the list of zero or more items associated with the
    # search results, search history, bookmarks, etc.
    #
    # @return [Array]
    #
    attr_reader :item_list

    # Interpret :documents as Array<Bookmark>.
    #
    # @return [Hash]
    #
    def bookmarks
      full = options[:full]
      docs = options[:doc] && documents.map { |doc| [doc.id, doc] }.to_h
      item_list.map { |item|
        next unless item.is_a?(Bookmark)
        entry = {
          document_id:    item.document_id,
          document_type:  item.document_type.to_s,
          search_lens:    item.lens,
          updated_at:     item.updated_at,
          created_at:     item.created_at,
        }
        full && entry.merge!(
          title:        item.user_type, # TODO: not persisted; should it be?
          id:           item.id,
          user_id:      item.user_id,
          user_type:    item.user_type,
        )
        docs && entry.merge!(doc: docs[item.document_id])
        entry
      }.compact.as_json
    end

    # Interpret :documents as Array<Search>.
    #
    # @return [Hash]
    #
    def searches
      full = options[:full]
      item_list.map { |item|
        next unless item.is_a?(Search)
        entry = {
          query_params: item.sorted_query,
          updated_at:   item.updated_at,
          created_at:   item.created_at,
        }
        full && entry.merge!(
          id:           item.id,
          user_id:      item.user_id,
          user_type:    item.user_type,
        )
        entry
      }.compact.as_json
    end

  end

end

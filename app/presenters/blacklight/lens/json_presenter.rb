# app/presenters/blacklight/lens/json_presenter.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'concerns/presenter_behaviors'

module Blacklight::Lens

  # Blacklight::Lens::JsonPresenter
  #
  # @see Blacklight::JsonPresenter
  #
  class JsonPresenter < Blacklight::JsonPresenter

    include CatalogHelper
    include Blacklight::Lens::PresenterBehaviors
    include Blacklight::Lens::Facet

    # =========================================================================
    # :section: Blacklight::JsonPresenter overrides
    # =========================================================================

    public

    # Initialize an instance, accepting arguments as needed to pass to the
    # initializer of the superclass.
    #
    # @param [Array] args
    #
    # @option args [Blacklight::Lens::Response]
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
      @response = @documents = @blacklight_config = @item_list = @facets = nil
      facet_counts_type = Blacklight::Solr::Response::Facets::FacetField
      args.each do |v|
        case v
          when Blacklight::Solr::Response         then @response          = v
          when ActiveRecord::Relation             then @item_list         = v
          when Blacklight::Configuration          then @blacklight_config = v
          when Blacklight::Solr::Response::Facets then @facets            = v
          else
            array = Array.wrap(v).reject(&:blank?)
            case array.first
              when nil                                  then # ignore
              when Blacklight::Document                 then @documents = array
              when Blacklight::Facet, facet_counts_type then @facets    = array
              else
                error = "#{array.first.class} unexpected: #{array.inspect}"
                raise error unless Virgo.production?
                Log.warn("#{self.class}: #{error}")
            end
        end
      end
      @facets            ||= @response&.dig(:facet_counts, :facet_fields) || {}
      @documents         ||= @response&.documents || []
      @item_list         ||= @documents
      @blacklight_config ||= default_blacklight_config
    end

    # documents
    #
    # @return [Array<Blacklight::Document>]
    #
    # This method overrides:
    # @see Blacklight::JsonPresenter#documents
    #
    def documents
      @documents
    end

    # search_facets
    #
    # @return [Array<Blacklight::Lens::Response::Facets::FacetField>]
    #
    # This method overrides:
    # @see Blacklight::JsonPresenter#search_facets
    #
    def search_facets
      @facets || super
    end

    # Extract the pagination info from the response object.
    #
    # @return [Hash]
    #
    def pagination_info
      @response ? super : {}
    end

    # =========================================================================
    # :section: Blacklight::ShowPresenter replacements
    # =========================================================================

    public

    # For the sake of Blacklight::Lens::PresenterBehaviors#field_values.
    #
    # @return [Blacklight::Document]
    #
    def document
      documents.first
    end

    # For consistency with Blacklight::ShowPresenter.
    #
    # @return [Blacklight::Configuration]
    #
    def configuration
      @blacklight_config
    end

    # For consistency with Blacklight::ShowPresenter.
    #
    # @return [ActionView::Base, nil]
    #
    def view_context
    end

    # Render a field value.
    #
    # @param [String, Symbol] field
    # @param [Hash, nil]      opt
    #
    # @option opt [Boolean] :raw
    # @option opt [String]  :value
    #
    # @return [Array<String>]
    #
    def field_value(field, opt = nil)
      opt = opt ? opt.dup : {}
      opt[:raw] = true
      field_values(field_config(field), opt)
    end

    # Get the configuration entry for a field.
    #
    # @param [String, Symbol] field
    #
    # @return [Blacklight::Configuration::Field]
    #
    def field_config(field)
      configuration.show_fields.fetch(field) do
        Blacklight::Configuration::NullField.new(field)
      end
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
          document_id:   item.document_id,
          document_type: item.document_type.to_s,
          lens:          item.lens,
          updated_at:    item.updated_at,
          created_at:    item.created_at,
        }
        full && entry.merge!(
          title:         item.user_type, # TODO: not persisted; should it be?
          id:            item.id,
          user_id:       item.user_id,
          user_type:     item.user_type,
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

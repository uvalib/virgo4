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
    # @option args [Blacklight::Controller]
    # @option args [Blacklight::Configuration]
    # @option args [ActiveRecord::Associations::CollectionProxy]
    #
    # @option args.last [Symbol]  :view   One of :index or :show.
    # @option args.last [Boolean] :full   Show full details for each item
    # @option args.last [Boolean] :doc    Show document (for bookmarks);
    #                                       default: *true*.
    #
    # This method overrides:
    # @see Blacklight::JsonPresenter#initialize
    #
    def initialize(*args)
      @options = args.extract_options!
      @options[:doc] = true unless @options.key?(:doc)
      @response = @item_list = @view_context = @blacklight_config =
        @facets = @documents = nil
      facet_counts_type = Blacklight::Lens::Response::Facets::FacetField
      args.compact.each do |v|
        @options[:view] ||= :show if v.is_a?(Blacklight::Document)
        array = nil
        case v
          when Blacklight::Lens::Response         then @response          = v
          when ActiveRecord::Relation             then @item_list         = v
          when Blacklight::Controller             then @view_context      = v
          when Blacklight::Configuration          then @blacklight_config = v
          when Blacklight::Lens::Response::Facets then @facets            = v
          else array = Array.wrap(v).reject(&:blank?)
        end
        next unless array.present?
        case array.first
          when Blacklight::Facet, facet_counts_type
            @facets = array
          when Blacklight::Document
            @documents = array
            @options[:view] ||= :index
          else
            error = "#{array.first.class} unexpected: #{array.inspect}"
            raise error unless Virgo.production?
            Log.warn("#{self.class}: #{error}")
        end
      end
      @facets            ||= @response&.dig(:facet_counts, :facet_fields) || {}
      @documents         ||= @response&.documents || []
      @item_list         ||= @documents
      @blacklight_config ||= @view_context&.blacklight_config
      @blacklight_config ||= default_blacklight_config
      @options[:view]    ||= :show
      @options[:view] = @options[:view].to_sym if @options[:view].is_a?(String)
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
      @facets || (@response ? super : [])
    end

    # Extract the pagination info from the response object.
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see Blacklight::JsonPresenter#pagination_info
    #
    def pagination_info
      @response ? super : {}
    end

    # =========================================================================
    # :section: Blacklight::Lens::PresenterBehaviors overrides
    # =========================================================================

    public

    # Render a field value.
    #
    # @param [String, Symbol, Blacklight::Configuration::Field] field
    # @param [Hash, nil] opt
    #
    # @option opt [Boolean] :raw
    # @option opt [String]  :value
    #
    # @return [Array<String>]
    #
    def field_value(field, opt = nil)
      opt ||= {}
      super(field, opt.merge(raw: true, blacklight_config: configuration))
    end

    # =========================================================================
    # :section: Blacklight::DocumentPresenter replacements
    # =========================================================================

    public

    # For the sake of Blacklight::Lens::PresenterBehaviors#field_values.
    #
    # @return [Blacklight::Document]
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#document
    #
    def document
      documents.first
    end

    # For consistency with Blacklight::ShowPresenter.
    #
    # @return [Blacklight::Configuration]
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#configuration
    #
    def configuration
      @blacklight_config
    end

    # For consistency with Blacklight::ShowPresenter.
    #
    # @return [Blacklight::Controller]
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#view_context
    #
    def view_context
      @view_context
    end

    # All the fields for this view that should be rendered.
    #
    # @return [Hash{String=>Blacklight::Configuration::Field}]
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#fields_to_render
    #
    def fields_to_render
      fields.select do |_, field_cfg|
        render_field?(field_cfg) && has_value?(field_cfg)
      end
    end

    # =========================================================================
    # :section: Blacklight::DocumentPresenter replacements
    # =========================================================================

    protected

    # Indicate whether the given field should be rendered in this context.
    #
    # @param [Blacklight::Configuration::Field] field_cfg
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#render_field?
    #
    def render_field?(field_cfg)
      if index_view
        view_context.should_render_field?(field_cfg)
      else
        view_context.should_render_field?(field_cfg, document)
      end
    end

    # Indicate whether a document has (or, might have, in the case of accessor
    # methods) a value for the given metadata field.
    #
    # As a convenience, this simply returns *true* if #index_view is true.
    #
    # @param [Blacklight::Configuration::Field] field_cfg
    #
    # Compare with:
    # @see Blacklight::DocumentPresenter#has_value?
    #
    def has_value?(field_cfg)
      index_view ||
        field_cfg.accessor ||
        document.has?(field_cfg.field) ||
        (document.has_highlight_field?(field_cfg.field) if field_cfg.highlight)
    end

    # =========================================================================
    # :section: Blacklight::ShowPresenter replacements
    # =========================================================================

    protected

    # fields
    #
    # @return [Hash{String=>Blacklight::Configuration::Field}]
    #
    # Compare with:
    # @see Blacklight::ShowPresenter#fields
    # @see Blacklight::IndexPresenter#fields
    #
    def fields
      if index_view
        configuration.index_fields_for(document)
      else
        configuration.show_fields_for(document)
      end
    end

    # Get the configuration entry for a field.
    #
    # @param [String, Symbol] field
    #
    # @return [Blacklight::Configuration::Field]
    #
    # Compare with:
    # @see Blacklight::ShowPresenter#field_config
    # @see Blacklight::IndexPresenter#field_config
    #
    def field_config(field)
      (index_view ? configuration.index_fields : configuration.show_fields)
        .fetch(field) { Blacklight::Configuration::NullField.new(field) }
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

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Indicate whether :index fields are being rendered.
    #
    # @return [TrueClass, FalseClass]
    #
    def index_view
      @options[:view] == :index
    end

  end

end

__loading_end(__FILE__)

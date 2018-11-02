# app/helpers/blacklight_configuration_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see BlacklightAdvancedSearch::ConfigurationHelperBehavior
#
module BlacklightConfigurationHelper

  include Blacklight::ConfigurationHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[BlacklightConfigurationHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::ConfigurationHelperBehavior overrides
  # ===========================================================================

  public

  # Index fields to display for a type of document.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::Field}]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#index_fields
  #
  def index_fields(lens = nil)
    blacklight_config_for(lens).index_fields
  end

  # Used in the document_list partial (search view) for building a select
  # element.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String,Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#sort_fields
  #
  def sort_fields(lens = nil)
    fields = active_sort_fields(lens)
    fields.map { |field, _| [sort_field_label(field), field.to_sym] }
  end
  deprecation_deprecate :sort_fields

  # active_sort_fields
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::SortField}]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#active_sort_fields
  #
  def active_sort_fields(lens = nil)
    blacklight_config_for(lens).sort_fields
      .select { |_, cfg| should_render_field?(cfg) }
  end

  # Used in the search form partial for building a select tag.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String, Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#search_fields
  #
  def search_fields(lens = nil)
    active_search_fields(lens)
      .map { |field, _| [label_for_search_field(field), field.to_sym] }
  end

  # active_search_fields
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::SearchField}]
  #
  def active_search_fields(lens = nil)
    blacklight_config_for(lens).search_fields
      .select { |_, cfg| should_render_field?(cfg) }
  end

  # Returns suitable argument to options_for_select method, to create an HTML
  # <select> based on #search_field_list.
  #
  # Skips search_fields marked with :include_in_simple_select => *false*
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(String, Symbol)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#search_field_options_for_select
  #
  def search_field_options_for_select(lens = nil)
    search_fields(lens)
  end

  # Used in the "app/views/catalog/_show_default.html.erb" partial.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::Field}]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_fields
  #
  def document_show_fields(lens = nil)
    blacklight_config_for(lens).show_fields
  end

  # Look up the label for the index field.
  #
  # @param [Object, nil]    lens      Default: `current_lens`.
  # @param [String, Symbol] field
  #
  # @return [String]
  #
  # @see Config::Common#field_label
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#index_field_label
  #
  def index_field_label(lens, field)
    lens ||= current_lens.key
    cfg = index_fields(lens)[field]
    cfg&.display_label(:index, lens) || ''
  end

  # Look up the label for the show field
  #
  # @param [Object]         lens      Default: `current_lens`.
  # @param [String, Symbol] field
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_field_label
  #
  def document_show_field_label(lens, field)
    lens ||= current_lens.key
    cfg = document_show_fields(lens)[field]
    cfg&.display_label(:show, lens) || ''
  end

  # Look up the label for the facet field.
  #
  # @param [String, Symbol] field
  # @param [Symbol, nil]    lens      Default: `current_lens`.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#facet_field_label
  #
  def facet_field_label(field, lens = nil)
    lens ||= current_lens.key
    cfg = blacklight_config_for(lens).facet_fields[field]
    cfg&.display_label(:facet, lens) || ''
  end

  # Look up the label for the view.
  #
  # @param [String, Symbol] view
  # @param [Symbol, nil]    lens      Default: `current_lens`.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#view_label
  #
  def view_label(view, lens = nil)
    lens ||= current_lens.key
    cfg = view && blacklight_config_for(lens).view[view]
    cfg&.display_label(view, lens) || ''
  end

  # Shortcut for commonly needed operation, look up display label for the key
  # specified. Returns "Keyword" if a label can't be found.
  #
  # @param [String, Symbol] field
  # @param [Symbol, nil]    lens      Default: `current_lens`.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#label_for_search_field
  #
  def label_for_search_field(field, lens = nil)
    lens ||= current_lens.key
    cfg = field && blacklight_config_for(lens).search_fields[field]
    cfg&.display_label(:search, lens) || ''
  end

  # Look up the label for the sort field.
  #
  # @param [String, Symbol] field
  # @param [Symbol, nil]    lens      Default: `current_lens`.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#sort_field_label
  #
  def sort_field_label(field, lens = nil)
    lens ||= current_lens.key
    cfg = field && blacklight_config_for(lens).sort_fields[field]
    cfg&.display_label(:sort, lens) || ''
  end

  # document_index_views
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::ViewConfig}]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_index_views
  #
  def document_index_views(lens = nil)
    blacklight_config_for(lens).view
      .select { |_, view_cfg| should_render_field?(view_cfg) }
  end

  # Filter #document_index_views to just views that should display in the view
  # type control.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [OrderedHash{String=>Blacklight::Configuration::ViewConfig}]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_index_view_controls
  #
  def document_index_view_controls(lens = nil)
    context = blacklight_configuration_context
    document_index_views(lens).select do |_, cfg|
      control = cfg.display_control
      control.nil? || context.evaluate_configuration_conditional(control)
    end
  end

  # Get the default index view type.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Symbol]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_document_index_view_type
  #
  def default_document_index_view_type(lens = nil)
    views = document_index_views(lens)
    views.find { |key, cfg| return key if cfg.default.present? }
    views.keys.first
  end

  # Indicate whether there are alternative views configured.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#has_alternative_views?
  #
  def has_alternative_views?(lens = nil)
    document_index_views(lens).keys.size > 1
  end

  # Maximum number of results for spell-checking.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Integer]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#spell_check_max
  #
  def spell_check_max(lens = nil)
    blacklight_config_for(lens).spell_max
  end

  # Used in the document list partial (search view) for creating a link to the
  # document show action.
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Symbol, String]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#document_show_link_field
  #
  # NOTE: The *doc* argument is *not* optional in this override.
  #
  def document_show_link_field(doc)
    fields = index_view_config(doc).title_field
    fields = Array.wrap(fields).map(&:to_sym)
    fields.first { |f| doc.has?(f) } || fields.first || doc.id
  end

  # Default sort field.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Blacklight::Configuration::SortField]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_sort_field
  #
  def default_sort_field(lens = nil)
    Blacklight::Configuration.new.default_search_field.
    fields = active_sort_fields(lens)
    fields.find { |_, cfg| return cfg if cfg.default.present? }
    fields.values.first
  end

  # The default value for search results per page.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Integer]
  #
  # @see Blacklight::Configuration#default_per_page
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#default_per_page
  #
  def default_per_page(lens = nil)
    blacklight_config_for(lens).default_per_page
  end

  # The available options for results per page, in the style of
  # #options_for_select.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Array<Array<(ActiveSupport::SafeBuffer, Integer)>>]
  #
  # This method overrides:
  # @see Blacklight::ConfigurationHelperBehavior#per_page_options_for_select
  #
  def per_page_options_for_select(lens = nil)
    blacklight_config_for(lens).per_page.map do |per_page|
      label = t('blacklight.search.per_page.label', count: per_page).html_safe
      [label, per_page]
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The sort key for the first sort field entry of the current Blacklight
  # configuration.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [String]
  #
  def default_sort_key(lens = nil)
    first_sort_key(lens)
  end

  # The sort key associated with relevance sort for the current Blacklight
  # configuration.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [String, nil]
  #
  def relevance_sort_key(lens = nil)
    first_sort_key(lens, %w(relevance relevancy))
  end

  # The sort key associated with date-received sort for the current
  # Blacklight configuration.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [String, nil]
  #
  def date_received_sort_key(lens = nil)
    first_sort_key(lens, %w(received newest))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # The sort key for the first matching sort entry for the current Blacklight
  # configuration.
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  # @param [Array, nil]  targets
  #
  # @return [String, nil]
  #
  def first_sort_key(lens = nil, targets = nil)
    fields  = active_sort_fields(lens)
    targets = Array.wrap(targets)
    if targets.present?
      fields.find { |key, _| return key if targets.include?(key) }
    else
      fields.keys.first
    end
  end

end

__loading_end(__FILE__)

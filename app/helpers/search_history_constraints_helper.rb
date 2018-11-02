# app/helpers/search_history_constraints_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::SearchHistoryConstraintsHelperBehavior
#
module SearchHistoryConstraintsHelper

  include Blacklight::SearchHistoryConstraintsHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[SearchHistoryConstraintsHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::SearchHistoryConstraintsHelperBehavior overrides
  # ===========================================================================

  public

  def render_search_to_s(params, opt = nil)
    shc_set(opt)
    render_search_to_s_q(params) + render_search_to_s_filters(params)
  end

  # Render the search query constraint.
  #
  # @param [ActionController::Parameters, Hash] params
  # @param [Hash, nil]                          opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_q
  #
  def render_search_to_s_q(params, opt = nil)
    query = params[:q]
    return ''.html_safe unless query.present?
    shc_set(opt)
    search = params[:search_field].to_s.presence
    if search
      skipped = [default_search_field.key.to_s]
      skipped << blacklight_config.advanced_search.url_key.to_s
      search  = nil if skipped.map(&:to_s).include?(search)
    end
    label = (search && label_for_search_field(search)) || ''
    value = render_filter_value(query)
    render_search_to_s_element(label, value)
  end

  # Render the search facet constraints.
  #
  # @param [ActionController::Parameters, Hash] params
  # @param [Hash, nil]                          opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_filters
  #
  def render_search_to_s_filters(params, opt = nil)
    shc_set(opt)
    facets = params[:f] || {}
    facets.map { |field, values|
      label  = facet_field_label(field)
      values = values.map { |value| render_filter_value(value, field) }
      values = values.join(and_operator).html_safe
      render_search_to_s_element(label, values)
    }.join("\n").html_safe
  end

  # Render a single search constraint.
  #
  # @param [String]                    key
  # @param [ActiveSupport::SafeBuffer] value
  # @param [Hash, nil]                 opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_search_to_s_element
  #
  def render_search_to_s_element(key, value, opt = nil)
    shc_set(opt)
    text = render_filter_name(key) + render_item(value, class: 'filter-values')
    css_class = shc_opt[:element_class] || 'constraint'
    render_item(text, class: css_class)
  end

  # Render a search constraint name.
  #
  # @param [String]    name
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_filter_name
  #
  def render_filter_name(name, opt = nil)
    return ''.html_safe if name.blank?
    shc_set(opt)
    text = t('blacklight.search.filters.label', label: name)
    css_class = shc_opt[:name_class] || 'filter-name'
    render_item(text, class: css_class)
  end

  # Render a search constraint value.
  #
  # @param [String]      value
  # @param [Object, nil] key
  # @param [Hash, nil]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::SearchHistoryConstraintsHelperBehavior#render_filter_value
  #
  def render_filter_value(value, key = nil, opt = nil)
    shc_set(opt)
    text = h(key ? facet_display_value(key, value) : value)
    css_class = shc_opt[:value_class] || 'filter-value'
    render_item(text, class: css_class)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a search AND connector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def and_operator
    @and_operator ||=
      begin
        op = t('blacklight.and', default: 'AND').upcase
        render_item(" #{op} ", class: 'filter-separator')
      end
  end

  # Render a search OR connector.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def or_operator
    @or_operator ||=
      begin
        op = t('blacklight.or', default: 'OR').upcase
        render_item(" #{op} ", class: 'filter-separator')
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render an item.
  #
  # @param [String]    text
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_item(text, opt = nil)
    if block_given?
      opt  = text if text.is_a?(Hash)
      text = yield
    end
    opt ||= {}
    content_tag(:span, text, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Element class overrides.
  #
  # @return [Hash{Symbol=>String}]
  #
  def shc_opt
    @shc_opt ||= {}
  end

  # Element class overrides.
  #
  # @param [Hash{Symbol=>String}] v
  #
  # @return [Hash, nil]
  #
  def shc_set(v)
    @shc_opt = v.slice(:element_class, :name_class, :value_class) if v.present?
  end

end

__loading_end(__FILE__)

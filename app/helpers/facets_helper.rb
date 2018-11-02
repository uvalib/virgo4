# app/helpers/facets_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::FacetsHelperBehavior
#
module FacetsHelper

  include Blacklight::Lens::Facet
  include Blacklight::FacetsHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[FacetsHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::FacetsHelperBehavior overrides
  # ===========================================================================

  public

  # Indicate whether any of the given fields have values.
  #
  # @param [Array<String>, nil] fields
  # @param [Symbol, nil]        lens
  #
  def has_facet_values?(fields = nil, lens = nil)
    fields ||= facet_field_names(lens)
    facets_from_request(fields).any? { |facet| should_render_facet?(facet) }
  end

  # Render a collection of facet fields.
  #
  # @param [Array<String>] fields
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_facet_limit
  #
  def render_facet_partials(fields = nil, options = nil)
    fields ||= facet_field_names
    facets_from_request(fields).map { |facet|
      render_facet_limit(facet, options)
    }.compact.join("\n").html_safe
  end

  # Renders a single section for facet limit with a specified Solr field used
  # for faceting.
  #
  # Can be overridden for custom display on a per-facet basis.
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet
  # @param [Hash] options             Passed to #render.
  #
  # @option options [String] :partial Partial to render
  # @option options [String] :layout  Partial layout to render
  # @option options [Hash]   :locals  Locals to pass to the partial
  #
  # Any other options will be moved into options[:locals].
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_facet_limit(facet, options = nil)
    cfg = facet_configuration_for_field(facet.name)
    return unless should_render_facet?(facet, cfg)
    options = options ? options.dup : {}
    options[:partial] ||= facet_partial_name(facet)
    options[:layout]  ||= 'facet_layout' unless options.key?(:layout)
    options[:locals]  ||= {}
    options[:locals][:field_name]    ||= facet.name
    options[:locals][:facet_field]   ||= cfg
    options[:locals][:display_facet] ||= facet
    options.except(:partial, :layout, :locals).keys.each do |key|
      options[:locals][key] = options.delete(key)
    end
    render(options)
  end

  # Renders the list of values.
  #
  # Removes any elements where render_facet_item returns a nil value. This
  # enables an application to filter undesirable facet items so they don't
  # appear in the UI.
  #
  # @param [Object]              paginator
  # @param [Object]              facet_field
  # @param [Symbol, String, nil] wrapping_element
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_facet_limit_list(paginator, facet_field, wrapping_element = nil)
    wrapping_element ||= :li
    paginator.items.map { |item|
      entry = render_facet_item(facet_field, item)
      content_tag(wrapping_element, entry) if entry.present?
    }.compact.join("\n").html_safe
  end

  # Renders a single facet item
  #
  # @param [Object] facet_field
  # @param [Object] item
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_facet_item(facet_field, item)
    if facet_in_params?(facet_field, item.value)
      render_selected_facet_value(facet_field, item)
    else
      render_facet_value(facet_field, item)
    end
  end

  # Indicate whether the facet should be rendered.
  # (Display when :show is *nil* or *true*.)
  #
  # By default, only render facets with items.
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet
  # @param [Blacklight::Configuration::FacetField, nil]     facet_cfg
  #
  def should_render_facet?(facet, facet_cfg = nil)
    facet_cfg ||= facet_configuration_for_field(facet.name)
    facet.items.present? && should_render_field?(facet_cfg, facet)
  end

  # Indicate whether a facet should be rendered as collapsed or not.
  #
  #   - if the facet is 'active', don't collapse
  #   - if the facet is configured to collapse (the default), collapse
  #   - if the facet is configured not to collapse, don't collapse
  #
  # @param [Blacklight::Configuration::FacetField] facet_cfg
  #
  def should_collapse_facet?(facet_cfg)
    !facet_field_in_params?(facet_cfg.key) && facet_cfg.collapse
  end

  # The name of the partial to use to render a facet field.
  #
  # Uses the value of the "partial" field if set in the facet configuration
  # otherwise uses "facet_pivot" if this facet is a pivot facet
  # defaults to 'facet_limit'
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet
  #
  # @return [String]
  #
  def facet_partial_name(facet = nil)
    cfg = facet_configuration_for_field(facet.name)
    cfg.try(:partial) || (cfg.pivot ? 'facet_pivot' : 'facet_limit')
  end

  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet_field
  # @param [Blacklight::Lens::Response::Facets::FacetItem]  item
  # @param [Hash, nil]                                      opt
  #
  # @option options [Boolean] :suppress_link    Do not display facet as a link.
  #
  # @return [String]
  #
  # Compare with:
  # @see #render_selected_facet_value
  #
  def render_facet_value(facet_field, item, opt = nil)
    opt ||= {}
    path  = (path_for_facet(facet_field, item) unless opt[:suppress_link])
    value = facet_display_value(facet_field, item)
    value = link_to(value, path, class: 'facet-select') if path
    label = content_tag(:span, value, class: 'facet-label')
    count = render_facet_count(item.hits)
    label + count
  end

  # Where should this facet link to?
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet_field
  # @param [String]                                         item
  # @param [Hash, nil]                                      opt
  #
  # @return [String]
  #
  def path_for_facet(facet_field, item, opt = nil)
    cfg = facet_configuration_for_field(facet_field)
    if cfg.url_method
      send(cfg.url_method, facet_field, item)
    else
      path_opt = search_state.add_facet_params_and_redirect(facet_field, item)
      path_opt.merge!(opt) if opt.present?
      search_action_path(path_opt)
    end
  end

  # Standard display of a SELECTED facet value (e.g. without a link and with a
  # remove button).
  #
  # @param [Blacklight::Lens::Response::Facets::FacetField] facet_field
  # @param [String]                                         item
  # @param [Hash, nil]                                      opt
  #
  # Compare with:
  # @see #render_facet_value
  #
  def render_selected_facet_value(facet_field, item, opt = nil)
    facet_value = facet_display_value(facet_field, item)
    facet_value = content_tag(:span, facet_value, class: 'selected')

    remove_icon = content_tag(:span, '✖', class: "remove-icon")
    remove_icon << content_tag(:span, '[remove]', class: 'sr-only')
    path_opt = search_state.remove_facet_params(facet_field, item)
    path_opt.merge!(opt) if opt.present?
    remove_path = search_action_path(path_opt)
    remove_link = link_to(remove_icon, remove_path, class: 'remove')

    label = facet_value + remove_link
    label = content_tag(:span, label, class: 'facet-label')
    count = render_facet_count(item.hits, class: 'selected')

    label + count
  end

  # Renders a count value for facet limits. Can be over-ridden locally
  # to change style. And can be called by plugins to get consistent display.
  #
  # @param [Numeric]   num            Number of facet results.
  # @param [Hash, nil] opt
  #
  # @option options [Array<String>]  an array of classes to add to count span.
  #
  # @return [String]
  #
  def render_facet_count(num, opt = nil)
    opt ||= {}
    classes = Array.wrap(opt[:class])
    classes << 'facet-count'
    classes = classes.reject(&:blank?).join(' ')
    content_tag(:span, class: classes) do
      t('blacklight.search.facets.count', number: number_with_delimiter(num))
    end
  end

  # Are any facet restrictions for a field in the query parameters?
  #
  # @param [String] field
  #
  def facet_field_in_params?(field)
    facet_params(field).present?
  end

  # Indicate whether the query parameters have the given facet field with the
  # given value.
  #
  # @param [String] field
  # @param [String] item facet value
  #
  def facet_in_params?(field, item)
    facet_value = facet_value_for_facet_item(item)
    facet_params(field).include?(facet_value)
  end

  # Get the values of the facet set in the blacklight query string.
  #
  # @param [String] field
  #
  # @return [Array<String>]
  #
  def facet_params(field)
    facet_key = facet_configuration_for_field(field)&.key
    Array.wrap(facet_key && params[:f] && params[:f][facet_key])
  end

  # Get the displayable version of a facet's value.
  #
  # @param [Object] field
  # @param [String] item              value
  #
  # @return [String]
  #
  def facet_display_value(field, item)
    value =
      item.respond_to?(:label) ? item.label : facet_value_for_facet_item(item)
    cfg = facet_configuration_for_field(field)
    if cfg.helper_method
      send(cfg.helper_method, value)
    elsif (qv = cfg.query && cfg.query[value])
      qv[:label]
    elsif (d = cfg.date)
      localize(value.to_datetime, (d unless d.is_a?(TrueClass)))
    else
      value
    end
  end

end

__loading_end(__FILE__)

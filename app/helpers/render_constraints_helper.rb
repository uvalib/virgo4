# app/helpers/render_constraints_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::RenderConstraintsHelperBehavior
#
module RenderConstraintsHelper

  include Blacklight::RenderConstraintsHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[RenderConstraintsHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::RenderConstraintsHelperBehavior overrides
  # ===========================================================================

  public

  # Render the facet constraints.
  #
  # @param [ActionController::Parameters, Hash, nil] localized_params
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraints_filters
  #
  def render_constraints_filters(localized_params = nil)
    localized_params ||= params.to_unsafe_h
    facets = localized_params[:f]
    facets = facets.to_unsafe_h if facets.respond_to?(:to_unsafe_h)
    facets ||= {}
    search_state = controller.search_state_class
    facets.map { |facet, values|
      path = search_state.new(localized_params, blacklight_config, controller)
      render_filter_element(facet, values, path)
    }.join("\n").html_safe
  end

  # Render a single facet's constraint.
  #
  # @param [String]                  facet   Field.
  # @param [Array<String>]           values  Selected facet values.
  # @param [Blacklight::SearchState] path    Query parameters.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_filter_element
  #
  def render_filter_element(facet, values, path)
    facet_config = facet_configuration_for_field(facet)
    facet_key    = facet_config.key
    facet_label  = facet_field_label(facet_key)
    Array.wrap(values).map { |value|
      next unless value.present?
      render_constraint_element(
        facet_label,
        facet_display_value(facet, value),
        remove:  search_action_path(path.remove_facet_params(facet, value)),
        classes: %W(filter filter-#{facet.parameterize})
      )
    }.compact.join("\n").html_safe
  end

  # Render a label/value constraint on the screen.
  #
  # Can be called by plugins and such to get application-defined rendering.
  #
  # Can be over-ridden locally to render differently if desired, although in
  # most cases you can just change CSS instead.
  #
  # Can pass in nil label if desired.
  #
  # @param [String] label
  # @param [String] value
  # @param [Hash]   options
  #
  # @option options [String]        :remove   URL to execute for remove action
  # @option options [Array<String>] :classes  CSS classes to add
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderConstraintsHelperBehavior#render_constraint_element
  #
  def render_constraint_element(label, value, options = nil)
    options ||= {}
    locals = { label: label, value: value, options: options }
    render_template('constraints_element', locals)
  end

end

__loading_end(__FILE__)

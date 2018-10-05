# lib/ext/blacklight/app/helpers/blacklight/catalog_helper_behavior.rb
#
# Inject Blacklight::CatalogHelperBehavior extensions and replacement methods.
#
# NOTE: Overriding Blacklight::FacetsHelperBehavior was problematic.

__loading_begin(__FILE__)

require 'blacklight'

override Blacklight::CatalogHelperBehavior do

=begin
  # ===========================================================================
  # :section: FacetsHelperBehavior overrides
  # ===========================================================================

  public

  # Renders a single facet item.
  #
  # @param [String] facet_field
  # @param [Object] item
  #
  # @return [Array<(String,Symbol)>]
  #
  # @see Blacklight::FacetsHelperBehavior#render_facet_item
  #
  def render_facet_item(facet_field, item)
    if facet_in_params?(facet_field, item.value)
      render_selected_facet_value(facet_field, item)
    elsif advanced_facet_in_params?(facet_field, item.value)
      render_selected_facet_value(facet_field, item)
    else
      render_facet_value(facet_field, item)
    end
  end

  # Indicate whether *item* is in an exclusive-OR facet selection.
  #
  # @param [String] facet_field
  # @param [String] item
  #
  # TODO: This probably belongs elsewhere...
  #
  def advanced_facet_in_params?(facet_field, item)
    facets = params[:f_inclusive]
    config = facet_configuration_for_field(facet_field)
    value  = facet_value_for_facet_item(item)
    facets && facets[config.key] && facets[config.key].include?(value)
  end
=end

end

__loading_end(__FILE__)

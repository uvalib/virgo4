# lib/ext/blacklight_advanced_search/app/helpers/blacklight_advanced_search/advanced_helper_behavior.rb
#
# Inject BlacklightAdvancedSearch::AdvancedHelperBehavior extensions and
# replacement methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search'

override BlacklightAdvancedSearch::AdvancedHelperBehavior do

=begin
  # Use configured facet partial name for facet or fallback on
  # 'advanced/facet_limit'.
  #
  # @param [Blacklight::Configuration::FacetField] display_facet
  #
  # @return [String]
  #
  def advanced_search_facet_partial_name(display_facet)
    facet_configuration_for_field(display_facet.name).try(:partial) ||
      'advanced/facet_limit'
  end
=end

end

__loading_end(__FILE__)

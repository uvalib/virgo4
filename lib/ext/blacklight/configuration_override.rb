# lib/ext/blacklight/configuration_override.rb
#
# Need to make sure that facets are expressed as strings not symbols.

__loading_begin(__FILE__)

require 'blacklight/configuration'

# =============================================================================
# :section: Inject Blacklight::Configuration replacement methods
# =============================================================================

override Blacklight::Configuration do

  # facet_configuration_for_field
  #
  # @param [String, Symbol] field     Solr facet name.
  #
  # @return [Blacklight::Configuration::FacetField]
  #
  def facet_configuration_for_field(field)
    field = field.to_s
    facet_fields[field] ||
      facet_fields.find { |_, field_def| field == field_def.field }&.last ||
      Blacklight::Configuration::FacetField.new(field: field).normalize!
  end

end

__loading_end(__FILE__)

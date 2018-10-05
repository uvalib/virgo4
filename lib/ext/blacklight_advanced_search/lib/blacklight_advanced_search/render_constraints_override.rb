# lib/ext/blacklight_advanced_search/lib/blacklight_advanced_search/render_constraints_override.rb
#
# Inject BlacklightAdvancedSearch::RenderConstraintsOverride extensions and
# replacement methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search/render_constraints_override'

override BlacklightAdvancedSearch::RenderConstraintsOverride do

  include Blacklight::SearchFields

end

__loading_end(__FILE__)

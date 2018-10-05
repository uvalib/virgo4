# lib/ext/blacklight_advanced_search/lib/blacklight_advanced_search/advanced_query_parser.rb
#
# Inject BlacklightAdvancedSearch::QueryParser extensions and replacement
# methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search/advanced_query_parser'

override BlacklightAdvancedSearch::QueryParser do

=begin
  # Extracts advanced-type filters from query params, including singleton
  # normal filters.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::QueryParser#filters
  #
  def filters
    @filters ||=
      {}.tap do |result|
        # Include advanced (OR'd) facet selections.
        (@params[:f_inclusive] || {}).each_pair do |field, value_array|
          result[field] = value_array.dup
        end
        # Include any normal (AND'ed) facet selections for facets that do not
        # also have an advanced (OR'd) set of choices and that do not have
        # multiple selections (which are, by definition, AND'ed together).
        (@params[:f] || {}).each_pair do |field, value_array|
          result[field] ||= value_array.dup if value_array.size == 1
        end
      end
  end
=end

end

__loading_end(__FILE__)

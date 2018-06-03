# lib/blacklight/eds/response.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Blacklight::Eds::Response
#
# Derived from:
# @see Blacklight::Solr::Response
#
class Blacklight::Eds::Response < Blacklight::Solr::Response

  require_dependency 'blacklight/eds/response/facets_eds'
  include FacetsEds

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  private

  # force_to_utf8
  #
  # @param [Hash, Array, String] value
  #
  # @return [Hash, Array, String]     Potentially modified value.
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#force_to_utf8
  #
  # NOTE: the original function doesn't appear to handle the String case right
  #
  def force_to_utf8(value)
    case value
      when Hash
        value.each { |k, v| value[k] = force_to_utf8(v) }
      when Array
        value.each { |v| force_to_utf8(v) }
      when String
        unless value.encoding == Encoding::UTF_8
          Log.warn {
            "Found a non UTF-8 value in #{self.class} with encoding " \
            "#{value.encoding} - #{value.inspect}"
          }
          value.force_encoding('UTF-8')
        end
    end
    value
  end

end

__loading_end(__FILE__)

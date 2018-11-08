# lib/ext/blacklight/lib/blacklight/solr/response.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/solr'
require 'blacklight/solr/response'

# Override Blacklight definitions.
#
# @see Blacklight::Solr::Response
#
module Blacklight::Solr::ResponseExt

  # ===========================================================================
  # :section: Blacklight::Solr::Response overrides
  # ===========================================================================

  public

  # document_factory
  #
  # @return [Class] (Blacklight::Lens::DocumentFactory)
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#document_factory
  #
  def document_factory
    blacklight_config&.document_factory || Blacklight::Solr::DocumentFactory
  end

  # If an array of documents were passed in through the initializer options,
  # use that instead of constructing documents from hash data.
  #
  # @return [Array<Blacklight::Document>]
  #
  # This method overrides:
  # @see Blacklight::Solr::Response#documents
  #
  def documents
    @documents ||=
      Array.wrap(options[:documents]).compact.presence ||
        (response['docs'] || []).map do |doc|
          document_factory.build(doc, self, options)
        end
  end

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
  # NOTE: the original function doesn't handle the String case properly
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

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Solr::Response => Blacklight::Solr::ResponseExt

__loading_end(__FILE__)

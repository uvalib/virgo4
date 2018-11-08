# lib/ext/blacklight/lib/blacklight/configuration/field.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/configuration'
require 'blacklight/configuration/field'
require 'blacklight/lens'

# Override Blacklight definitions.
#
# @see Blacklight::Configuration::Field
#
module Blacklight::Configuration::FieldExt

  # Prefixes for search service metadata fields which can be stripped to get
  # the base metadata field term, e.g. "eds_authors" -> "authors".
  FIELD_PREFIXES = %w(eds).deep_freeze
  FIELD_PREFIX_RE = Regexp.new(/^(#{FIELD_PREFIXES.join('|')})_/)

  # Suffixes appended to search service metadata fields which can be stripped
  # to get the base metadata field term, e.g. "format_facet" -> "format".
  FIELD_SUFFIXES = %w(facet display a e f t tl tp sort ssort).deep_freeze
  FIELD_SUFFIX_RE = Regexp.new(/_(#{FIELD_SUFFIXES.join('|')})$/)

  # ===========================================================================
  # :section: Blacklight::Configuration::Field overrides
  # ===========================================================================

  public

  # Return the configured label for the current field definition.
  #
  # @param [String, nil] context    The view context ('show', 'facet', etc).
  # @param [Symbol, nil] lens
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Configuration::Field#display_label
  #
  def display_label(context = nil, lens = nil)
    type = context.to_s.presence
    lens = Blacklight::Lens.key_for(lens)
    name = key.to_s.sub(FIELD_PREFIX_RE, '').sub(FIELD_SUFFIX_RE, '')
    keys = []
    keys << :"blacklight.#{lens}.#{type}_field.#{name}" if lens && type
    keys << :"blacklight.#{lens}.field.#{name}"         if lens
    keys << :"blacklight.#{type}_field.#{name}"         if type
    keys << :"blacklight.field.#{name}"
    keys << label
    keys << name.to_s.titleize
    keys.delete_if(&:blank?)
    field_label(*keys)
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Configuration::Field =>
         Blacklight::Configuration::FieldExt

__loading_end(__FILE__)

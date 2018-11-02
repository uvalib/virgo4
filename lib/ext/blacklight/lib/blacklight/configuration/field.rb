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

override Blacklight::Configuration::Field do

  # Prefixes for search service metadata fields which can be stripped to get
  # the base metadata field term, e.g. "eds_authors" -> "authors".
  FIELD_PREFIXES = %w(eds).deep_freeze
  FIELD_PREFIX_RE = Regexp.new(/^(#{FIELD_PREFIXES.join('|')})_/)

  # Suffixes appended to search service metadata fields which can be stripped
  # to get the base metadata field term, e.g. "format_facet" -> "format".
  FIELD_SUFFIXES = %w(facet display a e f t tl tp sort ssort).deep_freeze
  FIELD_SUFFIX_RE = Regexp.new(/_(#{FIELD_SUFFIXES.join('|')})$/)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the configured label for the current field definition.
  #
  # @param [String, nil] context    The view context ('show', 'facet', etc).
  # @param [Symbol, nil] lens
  #
  # @return [String]
  #
  def display_label(context = nil, lens = nil)
    type = context.to_s.sub(/_field$/, '').presence
    lens = Blacklight::Lens.key_for(lens)
    name = key.to_s.sub(FIELD_PREFIX_RE, '').sub(FIELD_SUFFIX_RE, '')
    keys = []
    keys << :"blacklight.#{lens}.#{type}.#{name}" if lens && type
    keys << :"blacklight.#{lens}.field.#{name}"   if lens
    keys << :"blacklight.#{type}.#{name}"         if type
    keys << :"blacklight.field.#{name}"
    keys << label
    keys << name.to_s.titleize
    keys.delete_if(&:blank?)
    field_label(*keys)
  end

end

__loading_end(__FILE__)

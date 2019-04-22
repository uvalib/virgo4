# app/models/concerns/ils/library_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/common'

# Ils::LibraryMethods
#
module Ils::LibraryMethods

  include Ils::Common
  extend  Ils::Common

  # Libraries that do not have checkout (for UVA persons).
  #
  # @type [Array<String, Regexp>]
  #
  RESERVE_LIBRARIES = codes %w(SPEC-COLL JAG)

  # Libraries that are too far away to be part of LEO delivery.
  #
  # @type [Array<String, Regexp>]
  #
  REMOTE_LIBRARIES = codes %w(BLANDY MT-LAKE)

  # Library codes that do not represent actual libraries.
  #
  # @type [Array<String, Regexp>]
  #
  NON_PHYSICAL_LIBRARIES = codes 'UVA-LIB'

  # Libraries from which LEO cannot deliver.
  #
  # @type [Array<String, Regexp>]
  #
  NON_LEO_LIBRARIES = (
    RESERVE_LIBRARIES + REMOTE_LIBRARIES + NON_PHYSICAL_LIBRARIES
  ).freeze

  # Libraries that should come after others in the availability list and in
  # summary holdings.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see #later_libraries
  #
  LATER_LIBRARY = {
    jag:     'JAG School',
    ivy:     'Ivy Stacks',
    blandy:  'Blandy Experimental Farm',
    mt_lake: 'Mountain Lake',
    at_sea:  'Semester at Sea',
  }.freeze

  # ===========================================================================
  # :section: Ils::Library "mixins"
  # ===========================================================================

  public

  # deliverable?
  #
  def deliverable?
    deliverable.present? && !is_jag?
  end

  # holdable?
  #
  def holdable?
    holdable.present?
  end

  # Indicate whether the library is not on Grounds.
  #
  def remote?
    remote.present?
  end

  # Indicate whether the given identifier matches the library instance.
  #
  # @param [String] s
  #
  def identifier?(s)
    s = s.to_s.downcase
    [id, name, code].find { |v| v.to_s.downcase == s }.present?
  end

  # A label for the library that may take up less room than the full name.
  #
  # @return [String]
  #
  def label
    ((id == 5) || (code == 'SCI-ENG')) ? 'Brown Sci. Eng.' : name
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # leoable?
  #
  # @param [String, nil] lib        Default: `code`.
  #
  def leoable?(lib = nil)
    !match?((lib || code), NON_LEO_LIBRARIES)
  end

  # online?
  #
  # @param [String, nil] lib        Default: `code`.
  #
  def online?(lib = nil)
    match?((lib || code), 'UVA-LIB')
  end

  # is_special_collections?
  #
  # @param [String, nil] lib        Default: `code`.
  #
  def is_special_collections?(lib = nil)
    match?((lib || code), 'SPEC-COLL')
  end

  # is_ivy?
  #
  # @param [String, nil] lib        Default: `code`.
  #
  def is_ivy?(lib = nil)
    match?((lib || code), 'IVY')
  end

  # is_jag?
  #
  # @param [String, nil] lib        Default: `code`.
  #
  def is_jag?(lib = nil)
    match?((lib || code), 'JAG')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Libraries that should come after others in the availability list and in
  # summary holdings.
  #
  # @return [Array<Symbol>]
  #
  # @see #LATER_LIBRARIES
  #
  def later_libraries
    LATER_LIBRARY.keys
  end

  # later_library
  #
  # @param [String] name_or_code
  #
  # @return [Symbol]
  # @return [nil]                     If this is not one of #later_libraries.
  #
  def later_library(name_or_code)
    LATER_LIBRARY.find do |key, name|
      library_name_or_code = [key, name].map { |v| v.to_s.dasherize.upcase }
      return key if match?(name_or_code, library_name_or_code)
    end
  end

end

__loading_end(__FILE__)

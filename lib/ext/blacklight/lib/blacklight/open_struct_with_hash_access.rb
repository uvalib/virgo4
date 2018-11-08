# lib/ext/blacklight/lib/blacklight/configuration/field.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/open_struct_with_hash_access'

# Override Blacklight definitions.
#
# @see Blacklight::OpenStructWithHashAccess
#
module Blacklight::OpenStructWithHashAccessExt

  # ===========================================================================
  # :section: Blacklight::OpenStructWithHashAccess overrides
  # ===========================================================================

  public

  # Create a new instance with the values of this OpenStruct merged with the
  # values of another OpenStruct or Hash.
  #
  # @param [Hash, OpenStructWithHashAccess] other_hash
  #
  # @return [OpenStructWithHashAccess]
  #
  # This method overrides:
  # @see Blacklight::OpenStructWithHashAccess#merge!
  #
  def merge!(other_hash)
    other_hash = other_hash.to_h unless other_hash.is_a?(Hash)
    @table.merge!(other_hash)
    self
  end

  # Create a new instance with the values of this OpenStruct merged with the
  # values of another OpenStruct or Hash.
  #
  # @param [Hash, OpenStructWithHashAccess] other_hash
  #
  # @return [OpenStructWithHashAccess]
  #
  def deep_merge(other_hash)
    other_hash = other_hash.to_h unless other_hash.is_a?(Hash)
    other_hash = @table.deep_merge(other_hash)
    self.class.new(other_hash)
  end

  # Merge the values of another OpenStruct or Hash into this instance.
  #
  # @param [Hash, OpenStructWithHashAccess] other_hash
  #
  # @return [OpenStructWithHashAccess]
  #
  def deep_merge!(other_hash)
    other_hash = other_hash.to_h unless other_hash.is_a?(Hash)
    @table.deep_merge!(other_hash)
    self
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::OpenStructWithHashAccess =>
         Blacklight::OpenStructWithHashAccessExt

__loading_end(__FILE__)

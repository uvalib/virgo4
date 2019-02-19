# lib/ext/blacklight/lib/blacklight/configuration/fields.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/configuration'
require 'blacklight/configuration/fields'
require 'blacklight/lens'

# Override Blacklight definitions.
#
# @see Blacklight::Configuration::Fields
#
module Blacklight::Configuration::FieldsExt

  # ===========================================================================
  # :section: Blacklight::Configuration::Fields overrides
  # ===========================================================================

  public

  # add_blacklight_field
  #
  # This override calls the Blacklight method and sets the field label from the
  # locale based on *config_key* and the field name.
  #
  # @return [Blacklight::OpenStructWithHashAccess]
  #
  # @see Blacklight::Configuration::Fields::ClassMethods#define_field_access
  #
  # This method overrides:
  # @see Blacklight::Configuration::Fields#add_blacklight_field
  #
  def add_blacklight_field(config_key, *args, &block)
    super(config_key, *args, &block).tap do |field|
      field.label ||= I18n.t("blacklight.#{config_key}.#{field.key}")
    end
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Configuration::Fields =>
         Blacklight::Configuration::FieldsExt

__loading_end(__FILE__)

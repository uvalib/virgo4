# app/controllers/concerns/blacklight/lens/facet.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Effective overrides for Blacklight::Facet
#
# == Usage Notes
# Anywhere that Blacklight::Facet would be used should be explicitly replaced
# with Blacklight::Lens::Facet (or a derivative).
#
module Blacklight::Lens::Facet

  extend ActiveSupport::Concern

  include Blacklight::Facet

  included do |base|
    __included(base, 'Blacklight::Lens::Facet')
  end

  # ===========================================================================
  # :section: Blacklight::Facet overrides
  # ===========================================================================

  public

  # A list of the facet field names from the configuration.
  #
  # @param [Symbol, nil] lens
  #
  # @return [Array<String>]
  #
  def facet_field_names(lens = nil)
    blacklight_config_for(lens).facet_fields.values.map(&:field)
  end

end

__loading_end(__FILE__)

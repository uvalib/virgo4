# app/controllers/concerns/blacklight/lens/facet.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Extensions to Blacklight to support Blacklight Lens.
#
# Compare with:
# @see Blacklight::Facet
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

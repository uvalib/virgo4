# app/helpers/about_helper/eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'curb'

# AboutHelper::Eds
#
# @see AboutHelper
#
module AboutHelper::Eds

  include AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::Eds]')
  end

  # A table of the EBSCO EDS field name suffixes for each Blacklight field type.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see self#get_eds_fields
  #
  EDS_TYPES = I18n.t('blacklight.about.eds.fields.types').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_eds_session
  #
  # @return [EBSCO::EDS::Session]
  #
  def get_eds_session
    eds_repository.eds_session
  end

  # Get EBSCO EDS fields organized by Blacklight field type.
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Hash}}]
  #
  # @see self#EDS_TYPES
  #
  # Compare with:
  # @see AboutHelper::Solr#get_solr_fields
  #
  def get_eds_fields

    eds_response = eds_repository.search
    facet_fields = eds_response.dig('facet_counts', 'facet_fields')&.keys || {}
    eds_fields   = eds_response.dig('response', 'docs')&.flat_map(&:keys)&.uniq

    lens_keys    = Blacklight::Lens.lens_keys
    lens_configs = lens_keys.map { |k| [k, blacklight_config_for(k)] }.to_h

    EDS_TYPES.map { |type, entry|
      prefix, suffix = value_array(entry, :prefix, :suffix)
      fields = (type == :facet) ? facet_fields : eds_fields
      table =
        fields.map { |field|
          field = field.to_s
          next unless prefix.blank? || field.start_with?(prefix)
          next unless suffix.blank? || field.end_with?(suffix)
          matching_config =
            lens_configs.select { |_, config|
              in_configuration?(field, type: type, config: config)
            }
          [field, { lenses: matching_config.keys }]
        }.compact.to_h
      [type, table]
    }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EBSCO EDS sidebar control buttons.
  #
  # @param [Hash{Symbol=>Hash}]
  #
  # @return [Hash{String=>Hash}]
  #
  # Compare with:
  # @see AboutHelper::Solr#solr_controls
  #
  def eds_controls(hash)
    form_controls(:eds, hash)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # eds_repository
  #
  # @return [Blacklight::Eds::Repository]
  #
  def eds_repository
    blacklight_config_for(:articles).repository
  end

end

__loading_end(__FILE__)

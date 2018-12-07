# app/helpers/about_helper/solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'curb'

# AboutHelper::Solr
#
# @see AboutHelper
#
module AboutHelper::Solr

  include AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::Solr]')
  end

  # A table of the Solr field name suffixes for each Blacklight field type.
  #
  # @type [Hash{Symbol=>String}]
  #
  # @see self#get_solr_fields
  #
  SOLR_TYPES =
    I18n.t('blacklight.about.solr.fields.types').deep_freeze

  # Definitions of the parts of the JSON returned from the Solr luke handler.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see self#get_solr_information
  #
  SOLR_DATA_TEMPLATE =
    I18n.t('blacklight.about.solr.status.data_template').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get Solr fields organized by Blacklight field type.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # @see self#SOLR_TYPES
  # @see self#get_solr_field_data
  #
  def get_solr_fields
    fields = get_solr_field_data
    SOLR_TYPES.map { |type, entry|
      suffix = entry.is_a?(Hash) ? entry[:suffix] : entry.to_s
      [type, fields.select { |field, _count| field.end_with?(suffix) }]
    }.to_h
  end

  # Get administrative information from Solr.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # @see self#SOLR_DATA_TEMPLATE
  # @see self#get_solr_admin_data
  #
  def get_solr_information
    SOLR_DATA_TEMPLATE.map { |route, template|
      [route, get_solr_admin_data(route, template)]
    }.to_h
  end

  # Indicate whether the given field name is in the current configuration.
  #
  # @param [Symbol]                         field
  # @param [Blacklight::Configuration, nil] config  Default value is
  #                                                 `default_blacklight_config`
  #
  def in_configuration?(field, config = nil)
    config ||= default_blacklight_config
    config.sort_field?(field) ||
      config.facet_field?(field) ||
      config.index_field?(field) ||
      config.show_field?(field)
  end

  # ===========================================================================
  # :section: Solr
  # ===========================================================================

  protected

  # Get a table of the fields defined in the Solr instance along with the count
  # of documents that have that field (or *nil* for non-indexed field types).
  #
  # @return [Hash{String=>Numeric}]
  # @return [Hash{String=>nil}]
  #
  # @see https://wiki.apache.org/solr/LukeRequestHandler
  #
  def get_solr_field_data(route = 'admin/luke?wt=xslt&tr=luke.xsl')
    data = get_solr_data(route)
    fields = data['fields'] || {}
    fields.map { |field, entry|
      [field, entry['docs'].presence]
    }.to_h
  end

  # get_solr_admin_data
  #
  # @param [String, Symbol] route     The last portion of the Solr request URL.
  # @param [Hash, nil]      template  A hash which defines the keys to be
  #                                     selected from the data.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def get_solr_admin_data(route, template = nil)
    data = get_solr_data(route, symbolize_names: true)
    template ||= SOLR_DATA_TEMPLATE[route.to_sym]
    deep_slice(data, template)
  end

  # Return a Hash from JSON data returned from Solr.
  #
  # @param [String, Symbol] route     The last portion of the Solr request URL.
  # @param [Hash, nil]      opt       Options to JSON#parse.
  #
  # @return [Hash]
  #
  def get_solr_data(route, opt = nil)
    opt ||= {}
    http = Curl.get("#{solr_url}/#{route}")
    data = http.body_str
    JSON.parse(data, opt) || {}
  end

  # Make a copy of *hash* which contains only the portions of the original that
  # match the structure of *template*.  At any level of the hierarchy, the
  # ordering of keys in *template* defines the ordering of keys in the result.
  #
  # @param [Hash] hash
  # @param [Hash] template
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def deep_slice(hash, template)
    hash ||= {}
    keys = template&.keys || []
    hash.slice(*keys).map { |k, v|
      if v.is_a?(Hash) && template[k].is_a?(Hash)
        v = deep_slice(v, template[k])
      elsif logger.debug? && !v.is_a?(expected = template[k].class)
        logger.debug {
          "#{__method__}: #{k}: expected #{expected}; data is #{v.class}"
        }
      end
      [k, v]
    }.to_h
  end

  # The base path to Solr for constructing requests.
  #
  # @return [String]
  #
  # TODO: Retrieve from blacklight.yml
  #
  def solr_url
    solr_proto = 'http'
    solr_host  = 'junco.lib.virginia.edu'
    solr_port  = '8080'
    solr_core  = 'test_core'
    '%s://%s:%s/solr/%s' % [solr_proto, solr_host, solr_port, solr_core]
  end

end

__loading_end(__FILE__)

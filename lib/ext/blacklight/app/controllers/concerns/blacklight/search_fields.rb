# lib/ext/blacklight/app/controllers/concerns/blacklight/search_fields.rb
#
# Inject Blacklight::SearchFields extensions and replacement methods.

__loading_begin(__FILE__)

require 'blacklight'

override Blacklight::SearchFields do

  # search_field_def_for_key
  #
  # @param [Symbol] key
  #
  # @return [Array<(String,Symbol)>]
  #
  # NOTE: Added for blacklight_advanced_search
  # TODO: Re-evaluate after the gem is compatible with Blacklight 7
  #
  def search_field_def_for_key(key)
    blacklight_config.search_fields[key]
  end

end

__loading_end(__FILE__)

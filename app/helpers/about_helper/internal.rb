# app/helpers/about_helper/internal.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper::Internal
#
# @see AboutHelper
#
module AboutHelper::Internal

  include AboutHelper::Common

  def self.included(base)
    __included(base, '[AboutHelper::Internal]')
  end

  # Environment variables that should be highlighted in the display.
  #
  # @type [Array<String>]
  #
  ENV_FEATURED = I18n.t('blacklight.about.property.env.featured').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Crucial information about the application.
  #
  # @return [Hash{Symbol=>String}]
  #
  def run_values
    {
      'Host server':  host_server,
      'RACK_ENV':     ENV['RACK_ENV'],
      'RAILS_ENV':    ENV['RAILS_ENV'],
      'Rails.env':    Rails.env,
    }
  end

  # URLs for services required by the application.
  #
  # @return [Hash{Symbol=>String}]
  #
  def url_values
    {
      'Solr URL':         Blacklight.connection_config[:url],
      'FIREHOSE_URL':     ENV['FIREHOSE_URL'],
      'FEDORA_REST_URL':  ENV['FEDORA_REST_URL'],
      'PDA_WEB_SERVICE':  ENV['PDA_WEB_SERVICE'],
      'COVER_IMAGE_URL':  ENV['COVER_IMAGE_URL'],
    }
  end

  # Database configuration values for the application.
  #
  # @return [Hash{Symbol=>String}]
  #
  def db_values
    db_config = Rails.application.config.database_configuration[Rails.env]
    {
      'Database host':    (db_config['host'] || 'localhost'),
      'Database name':    db_config['database'],
      'Database adapter': db_config['adapter'],
    }
  end

  # Environment variables for the application's process.
  #
  # @return [Hash{String=>String}]
  #
  def env_values
    ENV.keys.sort.map { |name| [name, ENV[name]] }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Highlighted listing of environment variables.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_env_values
    show_entries(env_values, ENV_FEATURED)
  end

end

__loading_end(__FILE__)

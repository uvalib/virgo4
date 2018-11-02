# lib/blacklight/eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight_advanced_search'

# Definitions for interacting with EBSCO EDS.
#
module Blacklight::Eds

  EDS_DEBUG        = ENV.fetch('EDS_DEBUG') { !Rails.env.production? }.freeze
  EDS_GUEST        = ENV.fetch('EDS_GUEST') { (!EDS_DEBUG).to_s }.freeze
  EDS_AUTH         = ENV.fetch('EDS_AUTH',  'ip').freeze
  EDS_TIMEOUT      = EDS_DEBUG ? 60 : 30 # seconds
  EDS_OPEN_TIMEOUT = EDS_DEBUG ? 12 : 10 # seconds
  EDS_LOG_LEVEL =
    ENV.fetch('EDS_LOG_LEVEL') { EDS_DEBUG ? 'DEBUG' : 'INFO' }.freeze

  # TODO: turn off sanitize/titleize in favor of Virgo 3 code and styling
  EDS_CONFIGURATION_OPTIONS = {
    debug:        EDS_DEBUG,
    guest:        EDS_GUEST,
    auth:         EDS_AUTH,
    timeout:      EDS_TIMEOUT,
    open_timeout: EDS_OPEN_TIMEOUT,
    log:          nil, # Rails.logger, # Log.logger, # Rails.root.join('log', 'faraday.log'),
    log_level:    EDS_LOG_LEVEL,
    decode_sanitize_html: true, # TODO: testing...
    titleize_facets:      true, # TODO: testing...
  }.deep_freeze

  # Parameters consumed by self#eds_session.
  #
  #   :eds_session_token is translated to :session_token
  #   :debug is used to suppress or activate EDS debug
  #
  # @return [Array<Symbol>]
  #
  EDS_SESSION_PARAMS = %i(
    authenticated
    debug
    eds_session_token
    reset
    session
  ).freeze

  # Parameters passed on to the EBSCO EDS API.
  #
  # @return [Array<Symbol>]
  #
  EDS_API_PARAMS = %i(caller guest session_token)

  # Parameters for EDS requests.
  #
  # @return [Array<Symbol>]
  #
  EDS_PARAMS = (EDS_SESSION_PARAMS + EDS_API_PARAMS).freeze

end

require_subdir(__FILE__, 'eds')

__loading_end(__FILE__)

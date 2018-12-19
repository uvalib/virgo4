# lib/ext/ebsco-eds/lib/ebsco/eds/configuration.rb
#
# Inject EBSCO::EDS::Configuration extensions and replacement methods.

__loading_begin(__FILE__)

# Override EBSCO::EDS definitions.
#
# @see EBSCO::EDS::Configuration
#
module EBSCO::EDS::ConfigurationExt

  DEFAULT_CONFIG_FILE = 'eds.yml'

  # Default expiration time.
  DEFAULT_EXPIRATION = 30.minutes

  # Lifetime of the auth token.
  AUTH_TOKEN_EXPIRATION = 30.minutes

  DEFAULT_CONFIG = {
    debug:                            false,
    guest:                            true,
    org:                              nil,
    auth:                             'user',
    auth_token:                       nil,
    session_token:                    nil,
    api_hosts_list:                   ['eds-api.ebscohost.com'],
    uid_auth_url:                     '/authservice/rest/uidauth',
    ip_auth_url:                      '/authservice/rest/ipauth',
    create_session_url:               '/edsapi/rest/CreateSession',
    end_session_url:                  '/edsapi/rest/EndSession',
    info_url:                         '/edsapi/rest/Info',
    search_url:                       '/edsapi/rest/Search',
    retrieve_url:                     '/edsapi/rest/Retrieve',
    citation_exports_url:             '/edsapi/rest/ExportFormat',
    citation_exports_formats:         'all',
    citation_styles_url:              '/edsapi/rest/CitationStyles',
    citation_styles_formats:          'all',
    user_agent:                       'EBSCO EDS GEM v0.0.1',
    interface_id:                     'edsapi_ruby_gem',
    log:                              'faraday.log',
    log_level:                        'INFO',
    max_attempts:                     3,
    max_results_per_page:             100,
    ebook_preferred_format:           'ebook-pdf',
    use_cache:                        true,
    eds_cache_dir:                    (ENV['TMPDIR'] || '/tmp').freeze,
    auth_cache_expires_in:            (AUTH_TOKEN_EXPIRATION - 5.minutes),
    info_cache_expires_in:            1.day,
    retrieve_cache_expires_in:        DEFAULT_EXPIRATION,
    search_cache_expires_in:          DEFAULT_EXPIRATION,
    export_format_cache_expires_in:   1.day,
    citation_styles_cache_expires_in: 1.day,
    timeout:                          60,
    open_timeout:                     12,
    max_page_jumps:                   6,
    max_page_jump_attempts:           10,
    recover_from_bad_source_type:     false,
    all_subjects_search_links:        false,
    decode_sanitize_html:             false,
    titleize_facets:                  false,
    citation_link_find:               '[.,]\s+(' \
                                        '&lt;i&gt;EBSCOhost|' \
                                        'viewed|' \
                                        'Available|' \
                                        'Retrieved from|' \
                                        'http:\/\/search.ebscohost.com|' \
                                        'Disponível em' \
                                      ').+$',
    citation_link_replace:            '.',
    citation_db_find:                 '',
    citation_db_replace:              '',
    ris_link_find:                    '',
    ris_link_replace:                 '',
    ris_db_find:                      '',
    ris_db_replace:                   '',
    adapter:                          :net_http_persistent
  }.freeze

  # Sanity check.
  unless DEFAULT_CONFIG[:auth_cache_expires_in] < AUTH_TOKEN_EXPIRATION
    raise 'auth_cache_expires_in must be less than the auth token expiration'
  end

  # ===========================================================================
  # :section: EBSCO::EDS::Configuration overrides
  # ===========================================================================

  public

  # Configuration defaults.
  #
  # This method overrides:
  # @see EBSCO::EDS::Configuration#initialize
  #
  def initialize
    @config = DEFAULT_CONFIG.deep_dup
  end

  # configure
  #
  # @param [Hash, nil] opts
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see EBSCO::EDS::Configuration#configure
  #
  def configure(opts = nil)
    opts = opts&.symbolize_keys&.select { |k, _| DEFAULT_CONFIG.include?(k) }
    @config.merge!(opts || {})
  end

  # Include configuration options from the indicated file; returns *nil* if the
  # file could not be found or was unusable.
  #
  # @param [String] file
  #
  # @return [Hash, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Configuration#configure_with
  #
  def configure_with(file)
    config = YAML.load_file(file || DEFAULT_CONFIG_FILE)
    configure(config)
  rescue Errno::ENOENT
    Log.info "#{file}: not found -- using defaults."
  rescue Psych::SyntaxError
    Log.warn "#{file}: invalid syntax -- using defaults."
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override EBSCO::EDS::Configuration => EBSCO::EDS::ConfigurationExt

__loading_end(__FILE__)

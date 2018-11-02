# lib/ext/ebsco-eds/lib/ebsco/eds/configuration.rb
#
# Inject EBSCO::EDS::Configuration extensions and replacement methods.

__loading_begin(__FILE__)

override EBSCO::EDS:: Configuration do

  #override Configuration do

  DEFAULT_CONFIG_FILE = 'eds.yml'

  DEFAULT_CONFIG = {
    debug:                        false,
    guest:                        true,
    org:                          nil,
    auth:                         'user',
    auth_token:                   nil,
    session_token:                nil,
    api_hosts_list:               ['eds-api.ebscohost.com'],
    ip_auth_url:                  '/authservice/rest/ipauth',
    uid_auth_url:                 '/authservice/rest/uidauth',
    create_session_url:           '/edsapi/rest/CreateSession',
    end_session_url:              '/edsapi/rest/EndSession',
    info_url:                     '/edsapi/rest/Info',
    search_url:                   '/edsapi/rest/Search',
    retrieve_url:                 '/edsapi/rest/Retrieve',
    user_agent:                   'EBSCO EDS GEM v0.0.1',
    interface_id:                 'edsapi_ruby_gem',
    log:                          'faraday.log',
    log_level:                    'INFO',
    max_attempts:                 3,
    max_results_per_page:         100,
    ebook_preferred_format:       'ebook-pdf',
    use_cache:                    true,
    eds_cache_dir:                (ENV['TMPDIR'] || '/tmp').freeze,
    adapter:                      :net_http_persistent,
    timeout:                      60,
    open_timeout:                 12,
    max_page_jumps:               6,
    max_page_jump_attempts:       10,
    recover_from_bad_source_type: false,
    all_subjects_search_links:    false,
    decode_sanitize_html:         false,
    titleize_facets:              false
  }.freeze

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Configuration defaults.
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
  def configure_with(file)
    config = YAML.load_file(file || DEFAULT_CONFIG_FILE)
    configure(config)
  rescue Errno::ENOENT
    Log.info "#{file}: not found -- using defaults."
  rescue Psych::SyntaxError
    Log.warn "#{file}: invalid syntax -- using defaults."
  end

  #end

end

__loading_end(__FILE__)

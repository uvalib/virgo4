# lib/ext/ebsco-eds/session_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::Session
# =============================================================================

override EBSCO::EDS::Session do

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Creates a new session.
  #
  # @param [Hash, nil] options
  #
  # @option options [String] :auth
  # @option options [String] :profile
  # @option options [String] :user
  # @option options [String] :pass
  # @option options [String] :guest
  # @option options [String] :org
  #
  # Any values not explicitly passed through options may be set through
  # environment variables:
  #
  # * +EDS_AUTH+    - authentication method: 'ip' or 'user'
  # * +EDS_PROFILE+ - profile ID for the EDS API
  # * +EDS_USER+    - user id attached to the profile
  # * +EDS_PASS+    - user password
  # * +EDS_GUEST+   - allow guest access: 'y' or 'n'
  # * +EDS_ORG+     - name of your institution or company
  #
  # == Examples
  # @example Through options
  #   session = EBSCO::EDS::Session.new {
  #     :auth    => 'user',
  #     :profile => 'edsapi',
  #     :user    => 'joe'
  #     :pass    => 'secret',
  #     :guest   => false,
  #     :org     => 'Acme University'
  #   }
  #
  # @example Through environment variables
  # Once you have environment variables set, simply create a session like this:
  #   session = EBSCO::EDS::Session.new
  #
  def initialize(options = nil)

    # Use override values from the indicated file (default 'eds.yml') if
    # present or the default configuration if there was some problem with
    # the YAML file (bad syntax, not found, etc.).
    options ||= {}
    eds_config = EBSCO::EDS::Configuration.new
    @config = eds_config.configure_with(options[:config])
    @config ||= eds_config.configure(options.except(:config))

    # Properties that are not in the configuration.
    @user    = options[:user]    || ENV['EDS_USER']
    @pass    = options[:pass]    || ENV['EDS_PASS']
    @profile = options[:profile] || ENV['EDS_PROFILE']

    unless @profile.present?
      raise EBSCO::EDS::InvalidParameter,
            'Session must specify a valid api profile.'
    end

    # Configuration options can be overridden by environment variables.
    @org       = ENV['EDS_ORG']       || @config[:org]
    @auth_type = ENV['EDS_AUTH']      || @config[:auth]
    @log_level = ENV['EDS_LOG_LEVEL'] || @config[:log_level]
    @cache_dir = ENV['EDS_CACHE_DIR'] || @config[:eds_cache_dir]

    # Boolean configuration options can be overridden by environment variables.
    @guest =
      if (env_value = ENV['EDS_GUEST'])
        !%w(false no off).include?(env_value.downcase)
      elsif @config.key?(:guest)
        @config[:guest]
      else
        true
      end

    @use_cache =
      if (env_value = ENV['EDS_USE_CACHE'])
        !%w(false no off).include?(env_value.downcase)
      else
        @config[:use_cache]
      end

    @debug =
      if (env_value = ENV['EDS_DEBUG'])
        %w(true yes on).include?(env_value.downcase)
      else
        @config[:debug]
      end

    @recover_130 =
      if (env_value = ENV['EDS_RECOVER_FROM_BAD_SOURCE_TYPE'])
        %w(true yes on).include?(env_value.downcase)
      else
        @config[:recover_from_bad_source_type]
      end

    @api_hosts_list =
      if (env_value = ENV['EDS_HOSTS'])
        env_value.to_s.split(/\s*,\s*/)
      else
        @config[:api_hosts_list].presence || []
      end

    # Setup logging.
    @logger =
      case (log = options[:log] || (@config[:log] if @debug)).presence
        when Logger
          log
        when String, Pathname
          unless log.to_s.start_with?('/')
            tmp_root = ENV.fetch('TMPDIR', '/tmp')
            log = File.join(tmp_root, log)
          end
          Logger.new(log).tap { |l| l.level = Logger.const_get(@log_level) }
      end

    # Setup caching options that will be used in #connection.
    @cache_opt =
      if @use_cache
        {
          store:      :file_store,
          cache_dir:  @cache_dir,
          logger:     @logger,
        }
      end

    # Other values that need to be initialized.
    @conn_adapter   = @config[:adapter]
    @api_host_index = 0
    @current_page   = 0
    @search_options = nil

    # Setup connection options.
    # @see Faraday::Connection#initialize
    # @see Faraday::ConnectionOptions#initialize
    @conn_opt = {
      url: ('https://' + @api_hosts_list[@api_host_index]),
      headers: {
        'Content-Type' => 'application/json;charset=UTF-8',
        'Accept'       => 'application/json',
        'User-Agent'   => @config[:user_agent],
      },
      request: {
        timeout:      @config[:timeout],
        open_timeout: @config[:open_timeout],
      }
    }

    # Establish session properties, acquiring them remotely as needed.
    @auth_token    = options[:auth_token].presence    || create_auth_token
    @session_token = options[:session_token].presence || create_session_token

    # Get search characteristics (from cache when possible).
    info  = do_request(:get, path: @config[:info_url])
    @info = EBSCO::EDS::Info.new(info, @config)

    if @debug
      if options.key?(:caller)
        Log.add('SESSION CALLER: ' + options[:caller].inspect)
        Log.add('CALLER OPTIONS: ' + options.inspect)
      end
      Log.add('AUTH TOKEN:    ' + @auth_token.inspect)
      Log.add('SESSION TOKEN: ' + @session_token.inspect)
    end

  end

  # Performs a search.
  #
  # @param [Hash]                  options
  # @param [TrueClass, FalseClass] add_actions      Default: *false*.
  # @param [TrueClass, FalseClass] increment_page   Default: *true*.
  #
  # @return [EBSCO::EDS::Results]
  #
  # == Options
  # * :query            - The search terms. (REQUIRED)
  #                       Format: {booleanOperator},{fieldCode}:{term}.
  #                       Example: SU:Hiking
  #
  # * :mode             - Search mode to be used.
  #                       Either: 'all' (default), 'any', 'bool', 'smart'
  #
  # * :results_per_page - The number of records retrieved with the search
  #                       results (between 1-100, default is 20).
  #
  # * :page             - Starting page number for the result set returned from
  #                       a search (if results per page = 10, and page number =
  #                       3 , this implies: I am expecting 10 records starting
  #                       at page 3).
  #
  # * :sort             - The sort order for the search results.
  #                       Either: 'relevance' (default), 'oldest', 'newest'
  #
  # * :highlight        - Specifies whether or not the search term is
  #                       highlighted using <highlight /> tags.
  #                       Either 'true' or 'false'.
  #
  # * :include_facets   - Specifies whether or not the search term is
  #                       highlighted using <highlight /> tags.
  #                       Either 'true' (default) or 'false'.
  #
  # * :facet_filters    - Facets to apply to the search. Facets are used to
  #                       refine previous search results.
  #                       Format: \{filterID},{facetID}:{value}[,{facetID}:{value}]*
  #                       Example: 1,SubjectEDS:food,SubjectEDS:fiction
  #
  # * :view             - Specifies the amount of data to return with the
  #                       response. Either:
  #                         'title': title only;
  #                         'brief' (default): Title + Source, Subjects;
  #                         'detailed': Brief + full abstract
  #
  # * :actions          - Actions to take on the existing query specification.
  #                       Example: addfacetfilter(SubjectGeographic:massachusetts)
  #
  # * :limiters         - Criteria to limit the search results by.
  #                       Example: LA99:English,French,German
  #
  # * :expanders        - Expanders that can be applied to the search.
  #                       Either: 'thesaurus', 'fulltext', 'relatedsubjects'
  #
  # * :publication_id   - Publication to search within.
  #
  # * :related_content  - Comma separated list of related content types to
  #                       return with the search results. Either:
  #                         'rs' (Research Starters)
  #                         'emp' (Exact Publication Match)
  #
  # * :auto_suggest     - Specifies whether or not to return search suggestions
  #                       along with the search results.
  #                       Either 'true' or 'false' (default).
  #
  # == Examples
  #
  #   results = session.search({
  #     query:            'abraham lincoln',
  #     results_per_page: 5,
  #     related_content:  ['rs','emp']
  #   })
  #
  #   results = session.search({
  #     query:            'volcano',
  #     results_per_page: 1,
  #     publication_id:   'eric',
  #     include_facets:   false
  #   })
  #
  # This method replaces:
  # @see EBSCO::EDS::Session#search
  #
  def search(options = {}, add_actions = false, increment_page = true)

    options = options.deep_stringify_keys
    @search_results = nil

    # Create/recreate the search options if nil or not passing actions.
    search = (@search_options if add_actions)
    search ||= EBSCO::EDS::Options.new(options, @info)

    # Only perform a search when there are query terms since certain EDS
    # profiles will throw errors when given empty queries.
    if search.SearchCriteria.Queries.present?
      @search_options = search

      # Get search results.
      @search_results = get_results(@search_options, options)
      @current_page   = @search_results.page_number if increment_page

      # Create temporary facet results if needed.
      # TODO: should this also be considering 'f_inclusive' facets?
      facets = options['f']
      if facets.present?
        # Create temporary format facet results if needed.
        target_facet = 'eds_publication_type_facet'
        if facets.key?(target_facet)
          tmp_options = options.except('f')
          tmp_options['f'] = options['f'].except(target_facet)
          tmp_search_options = EBSCO::EDS::Options.new(tmp_options, @info)
          tmp_search_options.Comment = 'temp source type facets'
          @search_results.temp_format_facet_results =
            get_results(tmp_search_options, tmp_options)
        end
        # Create temporary content provider facet results if needed.
        target_facet = 'eds_content_provider_facet'
        if facets.key?(target_facet)
          tmp_options = options.except('f')
          tmp_options['f'] = options['f'].except(target_facet)
          tmp_search_options = EBSCO::EDS::Options.new(tmp_options, @info)
          tmp_search_options.Comment = 'temp content provider facet'
          @search_results.temp_content_provider_facet_results =
            get_results(tmp_search_options, tmp_options)
        end
      end

    elsif @search_options.present?

      # Use existing/updated SearchOptions.
      @search_results = get_results(@search_options, options)
      @current_page   = @search_results.page_number if increment_page

    else

      @search_results = EBSCO::EDS::Results.new(empty_results, @config)

    end

    @search_results
  end

  # Display @search_options if debugging (@debug is *true*).
  #
  # @param [Symbol]              method
  # @param [String]              path
  # @param [EBSCO::EDS::Options] payload
  #
  # This method replaces:
  # @see EBSCO::EDS::Session#do_request
  #
  def do_request(method, path:, payload: nil, attempt: 0)
    if @debug
      Log.add {
        'EDS REQUEST ' \
        "method #{method.inspect}, " \
        "path #{path.inspect}, " \
        "payload #{payload.pretty_inspect}"
      }
    end
    super # Call the original method.
  end

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  private

  # connection
  #
  # @param [TrueClass, FalseClass, nil] use_cache
  #
  # @return [Faraday::Connection]
  #
  def connection(use_cache = @use_cache)
    Faraday.new(@conn_opt) do |conn|
      conn.headers['x-sessionToken']        = @session_token
      conn.headers['x-authenticationToken'] = @auth_token
      conn.use :eds_caching_middleware, @cache_opt if use_cache
      conn.use :eds_exception_middleware
      conn.request  :url_encoded
      conn.response :json, content_type: /\bjson$/
      conn.response :detailed_logger, @logger if @debug
      conn.adapter  @conn_adapter
    end
  end

  # Same as above but no caching.
  #
  # @return [Faraday::Connection]
  #
  def jump_connection
    connection(false)
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  public

  # Create a new method in order to query the session for the value of @guest.
  #
  # @return [TrueClass, FalseClass]
  #
  def guest
    @guest
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  private

  # Perform an API request an encapsulate the results.
  #
  # @param [Hash]      payload
  # @param [Hash, nil] options
  #
  # @return [EBSCO::EDS::Results]
  #
  def get_results(payload, options = {})
    resp = do_request(:post, path: '/edsapi/rest/Search', payload: payload)
    EBSCO::EDS::Results.new(resp, @config, @info.available_limiters, options)
  end

end

__loading_end(__FILE__)

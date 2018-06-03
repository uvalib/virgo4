# app/models/blacklight/eds/repository.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative('../eds')
require 'blacklight/eds/response'

module Blacklight::Eds

  # Blacklight::Eds::Repository
  #
  # A subclass of:
  # @see Blacklight::AbstractRepository
  #
  class Repository < Blacklight::AbstractRepository

    # =========================================================================
    # :section:
    # =========================================================================

    public

    EDS_DEBUG = ENV.fetch('EDS_DEBUG') { !Rails.env.production? }.freeze

    # TODO: turn off sanitize/titleize in favor Virgo 3 code and styling
    EDS_CONFIGURATION_OPTIONS = {
      debug:     EDS_DEBUG,
      guest:     ENV.fetch('EDS_GUEST') { EDS_DEBUG ? 'false' : 'true' },
      auth:      ENV.fetch('EDS_AUTH',  'ip'),
      log:       Log.logger, # Rails.root.join('log', 'faraday.log'),
      log_level: ENV.fetch('EDS_LOG_LEVEL') { EDS_DEBUG ? 'DEBUG' : 'INFO' },
      timeout:      (EDS_DEBUG ? 60 : 30), # seconds
      open_timeout: (EDS_DEBUG ? 12 : 10), # in seconds
      decode_sanitize_html: true, # TODO: testing...
      titleize_facets:      true, # TODO: testing...
    }.deep_freeze

    EDS_PARAMS = [
      # Consumed by #eds_init
      :reset,
      # Consumed by #eds_options
      :authenticated,                 # Stored as @authenticated
      :session,                       # Stored as @session
      :'previous-next-index',         # Stored as @prev_next_index
      :eds_session_token,             # Translated to :session_token
      :debug,                         # Use to suppress or activate EDS debug.
      # Passed on to EBSCO EDS API
      :caller,
      :guest,
      :session_token,
    ]

    # =========================================================================
    # :section: Blacklight::AbstractRepository overrides
    # =========================================================================

    public

    # Create a new self instance.
    #
    # @param [Blacklight::Configuration] config
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#initialize
    #
    def initialize(config)
      @blacklight_config = config || ArticlesController.blacklight_config
    end

    # Not used.
    #
    # @raise [RuntimeError]
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#connection
    #
    def connection
      self
    end

    # Get an item from EDS.
    #
    # @param [String, Array<String>] id
    # @param [Hash]                  req_params
    # @param [Hash]                  eds_params
    #
    # @return [Blacklight::Eds::Response]
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#find
    #
    # Compare with:
    # @see Blacklight::Solr::RepositoryExt#find
    #
    def find(id, req_params = nil, eds_params = nil)
      record = eds_get_record(id, eds_params)
      result = record.to_solr
      make_eds_response(result, req_params)
    end

    # Perform an EDS search.
    #
    # @param [SearchBuilder, Hash, nil] url_params
    # @param [Hash]                     eds_params
    #
    # @return [Blacklight::Eds::Response]
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#search
    #
    # Compare with:
    # @see Blacklight::Solr::RepositoryExt#search
    #
    def search(url_params = nil, eds_params = nil)
      send_and_receive(url_params, eds_params)
    end

    # =========================================================================
    # :section: Blacklight::Solr::Repository replacements
    # =========================================================================

    public

    # send_and_receive
    #
    # @param [Blacklight::SearchBuilder, ActionController::Parameters] search
    # @param [Hash] eds_params
    #
    # @return [Blacklight::Eds::Response]
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#send_and_receive
    #
    def send_and_receive(search = nil, eds_params = nil)
      benchmark('EDS fetch', level: :debug) do
        # Results list passes a full search_builder, detailed record only
        # passes params.
        params = { # TODO: make configurable
          hl:                       'on',
          include_image_quick_view: 'on',
          related_content:          'rs',
        }
        case search
          when Blacklight::SearchBuilder    then search = search.to_hash
          when ActionController::Parameters then search = search.to_unsafe_h
          else                                   # Assume search is a Hash.
        end
        params.merge!(search.stringify_keys) if search
        null_search = !params.key?('q')
        params['q'] = '*' if null_search # NOTE: null search required.
        q = params['q']

        # Perform the indicated search:
        #   [1] NEXT-PREVIOUS
        #   [2] LIST OF IDS (e.g., bookmarks, email, sms, cite)
        #   [3] REGULAR SEARCH
        eds = eds_session('bl-search', eds_params)
        result =
          if @prev_next_index # [1]
            params['previous-next-index'] = @prev_next_index
            eds.solr_retrieve_previous_next(params)
          elsif q.is_a?(Hash) && (ids = q['id']).present? # [2]
            eds.solr_retrieve_list(list: ids)
          else # [3]
            eds.search(params).to_solr
          end

        make_eds_response(result, params)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # fulltext_url
    #
    # @param [String] id
    # @param [String] type
    # @param [Hash]   _req_params
    # @param [Hash]   eds_params
    #
    # @return [String]
    # @return [nil]
    #
    def fulltext_url(id, type, _req_params = nil, eds_params = nil)
      record = eds_get_record(id, eds_params)
      record.fulltext_link(type)[:url]
    end

    # make_eds_response
    #
    # @param [?]    data
    # @param [Hash] req_params
    #
    # @return [Blacklight::Eds::Response]
    #
    def make_eds_response(data, req_params = nil)
      data ||= {}
      eds_documents(data)
      @blacklight_config.response_model.new(
        data,
        (req_params || {}),
        blacklight_config: @blacklight_config,
        document_model:    @blacklight_config.document_model,
      )
    end

    # Get a records from EDS.
    #
    # @param [String] id
    # @param [Hash]   eds_params
    #
    # @return [EBSCO::EDS::Record]
    #
    def eds_get_record(id, eds_params = nil)
      dbid, an = extract_dbid_an(id)
      eds_session('bl-repo-find', eds_params).retrieve(dbid: dbid, an: an)
    end

    # Construct EDS Session.
    #
    # @param [String] caller
    # @param [Hash]   eds_params
    #
    # @return [EBSCO::EDS::Session]
    #
    def eds_session(caller = nil, eds_params = nil)
      if caller.is_a?(Hash)
        eds_params = caller
        caller     = nil
      end
      eds_params = eds_options(eds_params)
      eds_init
      eds_params[:caller] = caller if caller.present?
      EBSCO::EDS::Session.new(eds_params)
    end

    # Construct EDS Session options while extracting values for internal use.
    #
    # @param [Hash] eds_params        EDS_PARAMS value or override of a
    #                                 EDS_CONFIGURATION_OPTIONS setting.
    #
    # @option eds_params [Boolean] :debug  @see self#EDS_PARAMS
    # @option eds_params [Boolean] :guest  @see self#EDS_PARAMS
    # @option eds_params [Boolean] :guest  @see self#EDS_PARAMS
    #
    # @return [Hash]                  Values to be passed on to EBSCO EDS API.
    #
    # @see self#EDS_PARAMS
    # @see self#EDS_CONFIGURATION_OPTIONS
    #
    def eds_options(eds_params)
      EDS_CONFIGURATION_OPTIONS.dup.tap do |result|
        result.merge!(eds_params) if eds_params.present?
        @guest           = !result.delete(:authenticated)
        @reset           = result.delete(:reset)
        @session         = result.delete(:session) || {}
        @prev_next_index = result.delete(:'previous-next-index')
        session_token    = result.delete(:eds_session_token)
        result[:session_token] = session_token if session_token
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Analyze an identifier into database ID and accession number to be used
    # to query EBSCO EDS.
    #
    # @param [String] id
    #
    # @return [Array<(String, String)>]
    #
    def extract_dbid_an(id)
      dbid, an = id.split('__')
      an.tr!('_', '.') if an.present?
      return dbid, an
    end

    # Extract the list of documents from an EDS response.
    #
    # @param [Blacklight::Eds::Response] data
    #
    # @return [Array<Hash>]
    #
    def eds_documents(data)
      data ||= {}
      docs = data.dig('response', 'docs')
      docs = [] unless docs.is_a?(Array)
      max  = docs.size - 1
      (0..max).each do |idx|
        next if docs[idx].is_a?(ActiveSupport::HashWithIndifferentAccess)
        docs[idx] = docs[idx].with_indifferent_access
      end
      eds_edit!(docs)
    end

    EDS_ID_KEYS  = %i(id eds_database_id eds_accession_number).freeze
    EDS_DOI_KEYS = %i(eds_document_doi).freeze

    # Update the EBSCO fields in one or more documents.
    #
    # @param [Hash, Array<Hash>] doc
    #
    # @return [doc]                   The modified document(s).
    #
    def eds_edit!(doc)
      case doc
        when Array
          doc.map! { |d| d.is_a?(Hash) ? eds_edit!(d) : d }
        when Hash
          # Adjust EDS item identifiers so that they can be used with Rails
          # paths.  (E.g., "/articles/db__idbase.part2" would appear to Rails
          # as ID "db__idbase" with format "part2" -- translating the dots
          # prevents Rails from interpreting it this way.)
          EDS_ID_KEYS.each { |k| doc[k] &&= doc[k].to_s.tr('.', '_') }
          # Normalize DOIs as the canonical URL path (regardless of how the
          # published supplied the DOI value).
          EDS_DOI_KEYS.each do |k|
            doc[k] &&=
              URI.parse(URI.escape(doc[k].to_s)).tap { |uri|
                uri.scheme = 'https'
                uri.host   = 'doi.org'
                uri.path   = '/' + uri.path unless uri.path.start_with?('/')
              }.to_s
          end
          # Allow the "composed title" to go through so that <searchLink> can
          # be styled as desired by CSS.
          doc[:eds_composed_title] &&= doc[:eds_composed_title].html_safe
      end
      doc
    end

    # eds_init
    #
    # @return [EBSCO::EDS::Session]   If a new session token was acquired.
    # @return [nil]                   If the current session is still valid.
    #
    def eds_init
      action =
        if !@session.key?(:guest)
          'new-session'
        elsif @reset || (@session[:guest] != @guest)
          'status-changed'
        end
      if action
        eds = EBSCO::EDS::Session.new(caller: action, guest: @guest)
        @session[:guest]             = eds.guest
        @session[:eds_session_token] = eds.session_token
        Log.debug {
          "EDS guest: #{@session[:guest].inspect}\n" \
          "EDS token: #{@session[:eds_session_token].inspect}\n" \
          "EDS info:  #{eds.info.inspect}"
        }
        @session
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # For debugging only.
    #
    # @param [EBSCO::EDS::Info, EBSCO::EDS::Session] info
    #
    # @return [void]
    #
    def eds_parse_info(info)
      info = info.info if info.is_a?(EBSCO::EDS::Session)
      @eds_results_per_page ||= info.max_results_per_page
      @eds_api_settings ||=
        info.api_settings.deep_symbolize_keys.rdup
      @eds_view_result_settings ||=
        info.view_result_settings.deep_symbolize_keys.rdup
      @eds_application_settings ||=
        info.application_settings.deep_symbolize_keys.rdup
      @eds_available_search_criteria ||=
        info.eds_available_search_criteria.deep_symbolize_keys.rdup
      info = @eds_available_search_criteria

      # These values should be:
      #
      # date:      'Date Newest'
      # date2:     'Date Oldest'
      # relevance: 'Relevance'
      #
      @eds_sorts ||=
        Array.wrap(info[:AvailableSorts]).map { |entry|
          [entry[:Id].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # TX: 'All Text'
      # AU: 'Author'
      # TI: 'Title'
      # SU: 'Subject Terms'
      # SO: 'Source'
      # AB: 'Abstract'
      # IS: 'ISSN'
      # IB: 'ISBN'
      #
      @eds_search_fields ||=
        Array.wrap(info[:AvailableSearchFields]).map { |entry|
          [entry[:FieldCode].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # relatedsubjects:              # default: *off*
      #   'Apply equivalent subjects'
      # thesaurus:                    # default: *off*
      #   'Apply related words'
      # fulltext:                     # default: *on*
      #   'Also search within the full text of the articles'
      #
      @eds_expanders ||=
        Array.wrap(info[:AvailableExpanders]).map { |entry|
          [entry[:Id].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # FT:   'Full Text'                       (Type = 'select')
      # FR:   'References Available'            (Type = 'select')
      # RV:   'Scholarly (Peer Reviewed) Journals' (Type = 'select')
      # SO:   'Journal Name'                    (Type = 'text')
      # AU:   'Author'                          (Type = 'text')
      # DT1:  'Published Date'                  (Type = 'ymrange')
      # TI:   'Title'                           (Type = 'text')
      # FT1:  'Available in Library Collection' (Type = 'select')
      # LA99: 'Language'                        (Type = 'multiselectvalue')
      #
      @eds_limiters ||=
        Array.wrap(info[:AvailableLimiters]).map { |entry|
          [entry[:Id].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # bool:  'Boolean/Phrase'
      # all:   'Find all my search terms'       (default: *on*)
      # any:   'Find any of my search terms'
      # smart: 'SmartText Searching'
      #
      @eds_search_modes ||=
        Array.wrap(info[:AvailableSearchModes]).map { |entry|
          [entry[:Mode].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # emp: 'Exact Match Publication'          (default: *on*)
      #
      @eds_related_content ||=
        Array.wrap(info[:AvailableRelatedContent]).map { |entry|
          [entry[:Type].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h

      # These values should be:
      #
      # AutoSuggest: 'Did You Mean'          (default: *on*)
      # AutoCorrect: 'Auto Correct'
      #
      @eds_did_you_mean_options ||=
        Array.wrap(info[:AvailableDidYouMeanOptions]).map { |entry|
          [entry[:Id].to_sym, entry[:Label].to_s]
        }.compact.uniq.to_h
    end

  end

end

__loading_end(__FILE__)

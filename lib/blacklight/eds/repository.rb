# lib/blacklight/eds/repository.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight/lens/repository'

module Blacklight::Eds

  # Blacklight::Eds::Repository
  #
  # @see Blacklight::AbstractRepository
  #
  class Repository < Blacklight::Lens::Repository

    # Request parameters used for suggestions.
    #
    # @see self#suggestions
    #
    SUGGEST_PARAMS = %i(q guest search_field session_token eds_session_token)

    # The number of suggestions to request for autosuggest.
    #
    # @type [Numeric]
    #
    # @see self#suggestions
    # @see Blacklight::Eds::Suggest::Response#SUGGESTION_COUNT
    #
    SUGGESTION_COUNT = Blacklight::Eds::Suggest::Response::SUGGESTION_COUNT

    # The fallback value for `blacklight_config.autocomplete_path`.
    #
    # @type [String]
    #
    DEF_AUTOCOMPLETE_PATH = 'suggest'

    # The fallback value for `blacklight_config.autocomplete_suggester`.
    #
    # @type [String]
    #
    DEF_AUTOCOMPLETE_SUGGESTER = 'suggest'

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
    def initialize(config, *)
      super(config)
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
    # @see Blacklight::Solr::Repository#find
    #
    def find(id, req_params = nil, eds_params = nil)
      record = eds_get_record(id, eds_params)
      result = record.to_solr
      make_eds_response(result, req_params)
    end

    # Perform an EDS search.
    #
    # @param [SearchBuilderEds, Hash, nil] url_params
    # @param [Hash]                        eds_params
    #
    # @return [Blacklight::Eds::Response]
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#search
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#search
    #
    def search(url_params = nil, eds_params = nil)
      send_and_receive(url_params, eds_params)
    end

    # =========================================================================
    # :section: Blacklight::Solr::Repository replacements
    # =========================================================================

    public

    # suggestions
    #
    # @param [Hash] req_params
    #
    # @return [Blacklight::Eds::Suggest::Response]
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#suggestions
    #
    def suggestions(req_params)
      url_params = req_params.slice(*SUGGEST_PARAMS)
      suggester  = suggester_name(url_params)
      token      = url_params.delete(:eds_session_token)
      url_params[:session_token] = token if token.present?
      url_params[:facet]         = 'false'
      url_params[:rows]          = SUGGESTION_COUNT

      result = search(url_params, debug: false)

      Blacklight::Eds::Suggest::Response.new(
        result,
        url_params,
        suggest_handler_path,
        suggester
      )
    end

    # send_and_receive
    #
    # @param [SearchBuilderEds, ActionController::Parameters] search
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
        case search
          when Blacklight::SearchBuilder    then search = search.to_hash
          when ActionController::Parameters then search = search.to_unsafe_h
          else                                   # Assume search is a Hash.
        end
        params = { # TODO: make configurable
          hl:                       'on',
          include_image_quick_view: 'on',
          related_content:          'rs',
        }
        params.merge!(search.stringify_keys) if search.present?

        # The request is a search.
        null_search = !params.key?('q')
        params['q'] = '*' if null_search # NOTE: null search required.
        query = params['q']

        # The request is for a list of items by ID.
        ids = (query['id'].presence if query.is_a?(Hash))

        # Special request to acquire previous and next items.
        eds_params ||= {}
        prev_next = eds_params.delete(:'previous-next-index')
        params['previous-next-index'] = prev_next if prev_next

        # Perform the indicated action and return the result as a Response.
        eds = eds_session('bl-search', eds_params)
        result =
          if prev_next
            eds.solr_retrieve_previous_next(params)
          elsif ids
            eds.solr_retrieve_list(list: ids)
          else
            eds.search(params).to_solr
          end

        make_eds_response(result, params)
      end
    end

    # =========================================================================
    # :section: Blacklight::Lens::Repository overrides
    # =========================================================================

    private

    # The EBSCO EDS URL path for autosuggest results.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Lens::Repository#suggest_handler_path
    #
    def suggest_handler_path
      blacklight_config.autocomplete_path || DEF_AUTOCOMPLETE_PATH
    end

    # The EBSCO EDS autosuggest handler modified by the presence of
    # :search_field in the supplied parameters.
    #
    # @param [SearchBuilder, Hash, nil] url_params
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Lens::Repository#suggester_name
    #
    def suggester_name(url_params = nil)
      blacklight_config.autocomplete_suggester ||= DEF_AUTOCOMPLETE_SUGGESTER
      super
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

      # Modify baseline EDS options with supplied options.
      eds_params = EDS_CONFIGURATION_OPTIONS.merge(eds_params || {})
      session = eds_params.delete(:session) || {}
      reset   = eds_params.delete(:reset)
      guest   = !eds_params.delete(:authenticated)
      token   = eds_params.delete(:eds_session_token)
      eds_params[:session_token] = token if token.present?

      # Determine whether a new EDS session token needs to be acquired.
      new_token =
        if !session.key?(:guest)
          'new-session'
        elsif reset || (session[:guest] != guest)
          'status-changed'
        end
      if new_token
        eds = EBSCO::EDS::Session.new(caller: new_token, guest: guest)
        session[:guest]             = eds.guest
        session[:eds_session_token] = eds.session_token
        Log.debug {
          "EDS guest: #{session[:guest].inspect}\n" \
          "EDS token: #{session[:eds_session_token].inspect}\n" \
          "EDS info:  #{eds.info.inspect}"
        }
      end

      # Create an EDS session for use in sending a request to EBSCO.
      eds_params[:caller] = caller if caller.present?
      EBSCO::EDS::Session.new(eds_params)
    end

    # Analyze an identifier into database ID and accession number to be used
    # to query EBSCO EDS.
    #
    # @param [String] id
    #
    # @return [Array<(String, String)>]
    #
    def extract_dbid_an(id)
      dbid, an = id.split('__')
      [dbid, an.to_s.tr('_', '.')]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Get a record from EBSCO EDS.
    #
    # @param [String] id
    # @param [Hash]   eds_params
    #
    # @return [EBSCO::EDS::Record]
    #
    def eds_get_record(id, eds_params = nil)
      dbid, an = extract_dbid_an(id)
      eds = eds_session('bl-repo-find', eds_params)
      eds.retrieve(dbid: dbid, an: an)
    end

    # Create an EBSCO EDS response object.
    #
    # @param [Hash] data
    # @param [Hash] params
    #
    # @return [Blacklight::Eds::Response]
    #
    # Compare with:
    # @see Blacklight::Solr::RepositoryExt#make_solr_response
    #
    def make_eds_response(data, params = nil)
      docs = eds_documents(data)
      params ||= {}
      options = { documents: docs, blacklight_config: blacklight_config }
      blacklight_config.response_model.new(data, params, options)
    end

    # Extract the list of documents from EDS response data.
    #
    # @param [Hash] data
    #
    # @return [Array<EdsDocument>]
    #
    def eds_documents(data)
      docs = data&.dig('response', 'docs')
      docs = Array.wrap(docs).compact
      factory   = blacklight_config.document_factory
      model_opt = { lens: blacklight_config.lens_key }
      docs.map { |doc| factory.build(doc, data, model_opt) }
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

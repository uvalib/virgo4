# lib/ext/blacklight/lib/blacklight/solr/repository.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/solr'
require 'blacklight/solr/repository'
require 'blacklight/lens'

override Blacklight::Solr::Repository do

  include Blacklight::Lens

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  VERBOSE_LOGGING =
    defined?(::BLACKLIGHT_VERBOSE_LOGGING) && ::BLACKLIGHT_VERBOSE_LOGGING

  SEARCH_FILTERS = %i(
    default_solr_parameters
    add_query_to_solr
    add_facet_fq_to_solr
    add_facetting_to_solr
    add_solr_fields_to_query
    add_paging_to_solr
    add_sorting_to_solr
    add_group_config_to_solr
    add_facet_paging_to_solr
  )

  ADV_SEARCH_FILTERS = %i(
    add_advanced_parse_q_to_solr
    add_advanced_search_to_solr
  )

  SUGGEST_FILTERS = %i(
    default_solr_parameters
    add_query_to_solr
    add_facet_fq_to_solr
  )

  CATALOG_FILTERS = %i(
    show_only_public_records
    show_only_discoverable_records
    show_only_lens_records
  )

  # ===========================================================================
  # :section: Blacklight::Solr::Repository overrides
  # ===========================================================================

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
    @blacklight_config ||= default_blacklight_config
  end

  # Find a single Solr document result (by id) using the document
  # configuration.
  #
  # @param [String]                   id           Item's unique key value.
  # @param [SearchBuilder, Hash, nil] url_params
  #
  # @return [Blacklight::Solr::Response]
  #
  # This method overrides:
  # @see Blacklight::Solr::Repository#find
  #
  def find(id, url_params = nil)
    path = blacklight_config.document_solr_path || blacklight_config.solr_path
    solr_params = base_document_solr_params(url_params)
    solr_params[blacklight_config.document_unique_id_param] = id
    send_and_receive(path, solr_params).tap do |response|
      docs = response&.documents
      raise Blacklight::Exceptions::RecordNotFound unless docs.present?
    end
  end

  # Execute a Solr search query.
  #
  # @param [SearchBuilder, Hash, nil] url_params
  #
  # @return [Blacklight::Solr::Response]
  #
  # This method overrides:
  # @see Blacklight::Solr::Repository#search
  #
  def search(url_params = nil)
    path        = blacklight_config.solr_path
    solr_params = base_solr_params(url_params)
    send_and_receive(path, solr_params)
  end

  # suggestions
  #
  # @param [SearchBuilder, Hash, nil] url_params
  #
  # @return [Blacklight::Suggest::Response]
  #
  def suggestions(url_params)
    path = suggest_handler_path
    suggester = url_params[:suggester] || suggester_name
    sb_filters  = { only: SUGGEST_FILTERS + CATALOG_FILTERS }
    solr_params = base_solr_params(url_params, sb_filters)
    solr_params[:'suggest.dictionary'] = suggester
    result = solr_send_and_receive(:get, suggest_handler_path, solr_params)
    Blacklight::Suggest::Response.new(result, url_params, path, suggester)
  end

  # Execute a Solr query.
  #
  # @overload send_and_receive(path, solr_params)
  #   Execute a solr query at the given path with the parameters
  #   @param [String] path          Default: `blacklight_config.solr_path`.
  #   @param [Blacklight::Solr::Request, Hash]   solr_params
  #
  # @overload send_and_receive(solr_params)
  #   @param [Blacklight::Solr::Request, Hash]   solr_params
  #
  # @return [Blacklight::Solr::Response]
  #
  # @see RSolr::Client#send_and_receive
  #
  # This method overrides:
  # @see Blacklight::Solr::Repository#send_and_receive
  #
  def send_and_receive(path, solr_params = nil)
    benchmark('Solr fetch', level: :debug) do

      # Send to Solr.
      cfg  = blacklight_config
      http = cfg.http_method
      solr_params ||= Blacklight::Solr::Request.new
      rsolr_response = solr_send_and_receive(http, path, solr_params)

      # Create a response object.
      opt = { document_model: cfg.document_model, blacklight_config: cfg }
      cfg.response_model.new(rsolr_response, solr_params, opt).tap do |r|
        Log.debug { "Solr response: #{r.inspect}" } if VERBOSE_LOGGING
      end

    end

  rescue Errno::ECONNREFUSED => e
    msg = +'Unable to connect to Solr instance using ' << connection.inspect
    msg << ': ' << e.inspect
    raise Blacklight::Exceptions::ECONNREFUSED, msg

  rescue RSolr::Error::Http => e
    raise Blacklight::Exceptions::InvalidRequest, e.message

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Encapsulates the point of contact with RSolr to facilitate debugging.
  #
  # @param [Symbol]                    http   Either :post or :get (default).
  # @param [String]                    path
  # @param [Blacklight::Solr::Request] solr_params
  #
  # @return [RSolr::HashWithResponse, nil]
  #
  def solr_send_and_receive(http, path, solr_params)
    Log.debug { "Solr query: #{http} #{path} #{solr_params.inspect}" }
    key = (http == :post) ? :data : :params
    connection.send_and_receive(path, method: http, key => solr_params)
  end

  # Base parameters for Solr document requests, starting with configured
  # default parameters, including additional constraints and any supplied
  # Solr parameters.
  #
  # @param [SearchBuilder, Hash, nil]         url_params
  # @param [Hash{Symbol=>Array<Symbol>}, nil] sb_filters
  #
  # @option sb_filters [Hash] :except     SearchBuilder processor_chain
  #                                         filters to be skipped.
  # @option sb_filters [Hash] :only       The (limited) set of SearchBuilder
  #                                         processor_chain filters to be
  #                                         allowed.
  #
  # @return [Blacklight::Solr::Request]
  #
  def base_document_solr_params(url_params = nil, sb_filters = nil)
    sp = blacklight_config.default_document_solr_params || {}
    qt = blacklight_config.document_solr_request_handler.presence
    solr_params = Blacklight::Solr::Request.new(sp)
    solr_params[:qt] = qt || solr_params[:qt].presence || 'document'
    sb_filters ||= { except: SEARCH_FILTERS + %i(show_only_public_records) }
    merge_url_params!(solr_params, url_params, sb_filters)
  end

  # Base parameters for Solr search requests, starting with configured
  # default parameters, including additional constraints and any supplied
  # Solr parameters.
  #
  # @param [SearchBuilder, Hash, nil]         url_params
  # @param [Hash{Symbol=>Array<Symbol>}, nil] sb_filters
  #
  # @option sb_filters [Hash] :except     SearchBuilder processor_chain
  #                                         filters to be skipped.
  # @option sb_filters [Hash] :only       The (limited) set of SearchBuilder
  #                                         processor_chain filters to be
  #                                         allowed.
  #
  # @return [Blacklight::Solr::Request]
  #
  def base_solr_params(url_params = nil, sb_filters = nil)
    sp = blacklight_config.default_solr_params || {}
    qt = blacklight_config.qt.presence
    solr_params = Blacklight::Solr::Request.new(sp)
    solr_params[:qt] = qt || solr_params[:qt].presence || 'search'
    sb_filters ||= {} # NOTE: a placeholder for now (no filters are skipped)
    merge_url_params!(solr_params, url_params, sb_filters)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Apply filters by modifying *solr_params*.
  #
  # @param [Blacklight::Solr::Request] solr_params
  # @param [SearchBuilder, Hash, nil]  url_params
  # @param [Hash, nil]                 sb_filters
  #
  # @option sb_filters [Hash] :except     SearchBuilder processor_chain
  #                                         filters to be skipped.
  # @option sb_filters [Hash] :only       The (limited) set of SearchBuilder
  #                                         processor_chain filters to be
  #                                         allowed.
  #
  # @return [Blacklight::Solr::Request]   The modified *solr_params*.
  #
  # @see Blacklight::Solr::SearchBuilderBehavior#processed_parameters
  #
  def merge_url_params!(solr_params, url_params = nil, sb_filters = nil)
    if url_params.present?
      sb_filters ||= {}
      sb_class = blacklight_config.search_builder_class
      unless url_params.is_a?(sb_class)
        # Wrap parameters in a SearchBuilder.
        sb =
          if sb_filters.is_a?(Array)
            sb_class.new(sb_filters, self)
          else
            sb_class.new(self)
          end
        # Ensure that certain Solr fields passed through *url_params* will be
        # preserved even though SearchBuilder does not work with them.
        url_params ||= {}
        url_params.reverse_merge!(controller: blacklight_config.lens_key)
        merge_params, url_params =
          url_params.partition { |k, _| %i(facet fl).include?(k.to_sym) }
        url_params = sb.with(url_params.to_h).merge(merge_params.to_h)
      end
      only   = Array.wrap(sb_filters[:only])
      except = Array.wrap(sb_filters[:except])
      except += (url_params.processor_chain - only) if only.present?
      url_params = url_params.except(*except) if except.present?
      solr_params.merge!(url_params.to_hash.with_indifferent_access)
    end
    solr_params.delete_if { |k, v| k.blank? || v.blank? }
  end

end

__loading_end(__FILE__)

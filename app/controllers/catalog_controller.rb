# frozen_string_literal: true
class CatalogController < ApplicationController
  include BlacklightAdvancedSearch::Controller

  include Blacklight::Catalog
  include Blacklight::DefaultComponentConfiguration
  include Blacklight::Marc::Catalog


  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {
      'facet.limit': -1
    }

    ## Class for sending and receiving requests from a search index
    # config.repository_class = Blacklight::Solr::Repository
    #
    ## Class for converting Blacklight's url parameters to into request parameters for the search index
    # config.search_builder_class = ::SearchBuilder
    #
    ## Model that maps search index responses to the blacklight response model
    # config.response_model = Blacklight::Solr::Response

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      qt:   'search',
      rows: 10
    }

    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select'
    #config.document_solr_path = 'get'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # solr field configuration for search results/index views
    config.index.title_field        = 'title_a'
    config.index.display_type_field = 'format_a'
    #config.index.thumbnail_field   = 'thumbnail_path_ss'

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # solr field configuration for document/show views
    config.show.title_field        = 'title_a'
    config.show.display_type_field = 'format_a'
    #config.show.thumbnail_field   = 'thumbnail_path_ss'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    #
    # set :index_range to true if you want the facet pagination view to have facet prefix-based navigation
    #  (useful when user clicks "more" on a large facet and wants to navigate alphabetically across a large set of results)
    # :index_range can be an array or range of prefixes that will be used to create the navigation (note: It is case sensitive when searching values)

=begin
    config.add_facet_field 'format', label: 'Format'
    config.add_facet_field 'pub_date_ssim', label: 'Publication Year', single: true
    config.add_facet_field 'subject_ssim', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'language_ssim', label: 'Language', limit: true
    config.add_facet_field 'lc_1letter_ssim', label: 'Call Number'
    config.add_facet_field 'subject_geo_ssim', label: 'Region'
    config.add_facet_field 'subject_era_ssim', label: 'Era'
=end
    config.add_facet_field 'library_f',                 label: 'Library',                             index_range: 'A'..'Z'
    config.add_facet_field 'location_f',                label: 'Current Location',                    index_range: 'A'..'Z',  show: false
    config.add_facet_field 'location2_f',               label: 'Location',                limit: 10,  index_range: 'A'..'Z'
    config.add_facet_field 'shadowed_location_f',       label: 'Shadowing',                                                   show: false
    config.add_facet_field 'format_f',                  label: 'Format',                  limit: 10
    config.add_facet_field 'call_number_broad_f',       label: 'Call Number',                         index_range: 'A'..'Z'
    config.add_facet_field 'call_number_narrow_f',      label: 'Call Number Range',       limit: 10,  index_range: 'A'..'Z'
    config.add_facet_field 'language_f',                label: 'Language',                limit: 10
    config.add_facet_field 'author_f',                  label: 'Author',                  limit: 10
    config.add_facet_field 'region_f',                  label: 'Geographic Area',         limit: 10
    config.add_facet_field 'subject_f',                 label: 'Subject',                 limit: 10
    config.add_facet_field 'subject_era_f',             label: 'Subject Era',             limit: 10
    config.add_facet_field 'topic_form_genre_f',        label: 'Genre',                   limit: 10
    config.add_facet_field 'composition_era_f',         label: 'Musical Composition Era', limit: 10
    config.add_facet_field 'instrument_f',              label: 'Musical Instrument',      limit: 10
    config.add_facet_field 'music_composition_form_f',  label: 'Musical Composition',     limit: 10
    config.add_facet_field 'oclc_f',                    label: 'OCLC',                    limit: 10,                          show: false
    config.add_facet_field 'barcode_f',                 label: 'Barcode',                 limit: 10,                          show: false
    config.add_facet_field 'date_indexed_f',            label: 'Date Indexed',            limit: 10,                          show: false
    config.add_facet_field 'source_f',                  label: 'Source',                  limit: 10

    config.add_facet_field 'example_pivot_field', label: 'Pivot Field', pivot: %w(format_f language_f)

    config.add_facet_field 'example_query_facet_field', label: 'Publication Range', query: {
       years_5:  { label: 'within 5 Years',  fq: "published_daterange:[#{Time.zone.now.year - 5  } TO *]" },
       years_10: { label: 'within 10 Years', fq: "published_daterange:[#{Time.zone.now.year - 10 } TO *]" },
       years_25: { label: 'within 25 Years', fq: "published_daterange:[#{Time.zone.now.year - 25 } TO *]" }
    }

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
=begin
    config.add_index_field 'title_tsim', label: 'Title'
    config.add_index_field 'title_vern_ssim', label: 'Title'
    config.add_index_field 'author_tsim', label: 'Author'
    config.add_index_field 'author_vern_ssim', label: 'Author'
    config.add_index_field 'format', label: 'Format'
    config.add_index_field 'language_ssim', label: 'Language'
    config.add_index_field 'published_ssim', label: 'Published'
    config.add_index_field 'published_vern_ssim', label: 'Published'
    config.add_index_field 'lc_callnum_ssim', label: 'Call number'
=end
    #config.add_index_field 'title_a',      label: 'Title'
    #config.add_index_field 'title_vern_a', label: 'Title'
    config.add_index_field 'author_a',      label: 'Author'
    config.add_index_field 'author_vern_a', label: 'Author'
    config.add_index_field 'format_a',      label: 'Format'
    config.add_index_field 'language_a',    label: 'Language'
    config.add_index_field 'call_number_a', label: 'Call Number'
    config.add_index_field 'library_a',     label: 'Library'
    config.add_index_field 'location_a',    label: 'Location'
    config.add_index_field 'score',         label: 'Score'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
=begin
    config.add_show_field 'title_tsim', label: 'Title'
    config.add_show_field 'title_vern_ssim', label: 'Title'
    config.add_show_field 'subtitle_tsim', label: 'Subtitle'
    config.add_show_field 'subtitle_vern_ssim', label: 'Subtitle'
    config.add_show_field 'author_tsim', label: 'Author'
    config.add_show_field 'author_vern_ssim', label: 'Author'
    config.add_show_field 'format', label: 'Format'
    config.add_show_field 'url_fulltext_ssim', label: 'URL'
    config.add_show_field 'url_suppl_ssim', label: 'More Information'
    config.add_show_field 'language_ssim', label: 'Language'
    config.add_show_field 'published_ssim', label: 'Published'
    config.add_show_field 'published_vern_ssim', label: 'Published'
    config.add_show_field 'lc_callnum_ssim', label: 'Call number'
    config.add_show_field 'isbn_ssim', label: 'ISBN'
=end
    config.add_show_field 'author_a',                 label: 'Author'
    config.add_show_field 'author_vern_a',            label: 'Author'
    config.add_show_field 'format_a',                 label: 'Format'
    config.add_show_field 'title_vern_a',             label: 'Title'
    config.add_show_field 'title_uniform_a',          label: 'Uniform Title'
    config.add_show_field 'title_series_a',           label: 'Series Title'
    config.add_show_field 'title_added_entry_a',      label: 'Additional Title'
    config.add_show_field 'title_alternate_a',        label: 'Alternate Title'
    config.add_show_field 'published_date',           label: 'Publication Date'
    config.add_show_field 'composition_era_a',        label: 'Musical Composition Era'
    config.add_show_field 'instrument_a',             label: 'Musical Instrument'
    #config.add_show_field 'instrument_raw_a',        label: 'Instrument (raw)'
    config.add_show_field 'isbn_isbn_a',              label: 'ISBN'
    config.add_show_field 'journal_title_a',          label: 'Journal'
    config.add_show_field 'journal_addnl_title_a',    label: 'Journal Title'
    config.add_show_field 'language_a',               label: 'Language'
    config.add_show_field 'lc_call_number_a',         label: 'LC Call Number'
    config.add_show_field 'call_number_a',            label: 'Call Number'
    config.add_show_field 'call_number_broad_a',      label: 'Call Number Section'
    config.add_show_field 'call_number_narrow_a',     label: 'Call Number Range'
    config.add_show_field 'library_a',                label: 'Library'
    config.add_show_field 'location_a',               label: 'Current Location'
    config.add_show_field 'location2_a',              label: 'Location'
    config.add_show_field 'shadowed_location_a',      label: 'Shadowing'
    config.add_show_field 'music_composition_form_a', label: 'Musical Composition'
    config.add_show_field 'oclc_t',                   label: 'OCLC'
    config.add_show_field 'region_a',                 label: 'Region'
    config.add_show_field 'subject_a',                label: 'Subject'
    config.add_show_field 'subject_era_a',            label: 'Subject Era'
    config.add_show_field 'subject_summary_a',        label: 'Summary'
    config.add_show_field 'topic_form_genre_a',       label: 'Genre'
    config.add_show_field 'title_notes_a',            label: 'Title Notes'
    config.add_show_field 'local_notes_a',            label: 'Local Notes'
    config.add_show_field 'url_a',                    label: 'Online Version'
    config.add_show_field 'url_supp_a',               label: 'Related Resource'
    config.add_show_field 'pda_catkey_a'
    config.add_show_field 'pda_coutts_library_a'
    config.add_show_field 'pda_isbn_a'
    config.add_show_field 'summary_holdings_a',       label: 'Holdings'
    config.add_show_field 'barcode_e',                label: 'Barcode'
    config.add_show_field 'shelfkey'
    config.add_show_field 'reverse_shelfkey'
    config.add_show_field 'marc_error_a',             label: 'MARC Errors'
    config.add_show_field 'date_indexed_a',           label: 'Date Indexed'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'


    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        'spellcheck.dictionary': 'title',
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'author',
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.qt = 'search'
      field.solr_parameters = {
        'spellcheck.dictionary': 'subject',
        qf: '${subject_qf}',
        pf: '${subject_pf}'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, published_date desc, title_sort asc', label: 'Relevance'
    config.add_sort_field 'published_date desc, title_sort asc',             label: 'Date'
    config.add_sort_field 'author_sort asc, title_sort asc',                 label: 'Author'
    config.add_sort_field 'title_sort asc, published_date desc',             label: 'Title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    #config.autocomplete_enabled = true # TODO: not there yet
    config.autocomplete_enabled = false
    config.autocomplete_path = 'suggest'
    # if the name of the solr.SuggestComponent provided in your solrcongig.xml is not the
    # default 'mySuggester', uncomment and provide it below
    # config.autocomplete_suggester = 'mySuggester'
  end
end

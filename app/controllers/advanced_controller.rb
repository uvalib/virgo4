# app/controllers/advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class AdvancedController < BlacklightAdvancedSearch::AdvancedController

  copy_blacklight_config_from(CatalogController).configure do |config|
    # name of Solr request handler, leave unset to use the same one your Blacklight
    # is ordinarily using (recommended if possible)
    # config.advanced_search.qt = 'advanced'

    ##
    # The advanced search form displays facets as a limit option.
    # By default it will use whatever facets, if any, are returned
    # by the Solr request handler in use. However, you can use
    # this config option to have it request other facet params than
    # default in the Solr request handler, in desired.
    config.advanced_search.form_solr_parameters ||= {}
    config.advanced_search.form_solr_parameters[:'facet.limit'] = -1

    # Narrow the set of facets to display.
    ignored_facets = %w(
      location_f
      shadowed_location_f
      author_f
      subject_f
      subject_era_f
      topic_form_genre_f
      oclc_f
      barcode_f
      date_indexed_f
      example_pivot_field
      example_query_facet_field
    )
    config.facet_fields
      .delete_if { |field, _| ignored_facets.include?(field) }
      .each_pair { |_, field_config| field_config.limit = -1 }

    # We are going to completely override the inherited search fields.
    config.search_fields.clear

    # TODO: "author_qf/author_pf" definitions incorrect in select_edismax.xml
    config.add_search_field('author') do |field|
      field.solr_parameters = {
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end

    # TODO: "title_qf/title_pf" definitions incorrect in select_edismax.xml
    config.add_search_field('title') do |field|
      field.solr_parameters = {
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    # TODO: "subject_qf/subject_pf" definitions incorrect in select_edismax.xml
    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        qf: '${subject_qf}',
        pf: '${subject_pf}'
      }
    end

    # TODO: Should there be "keyword_qf/keyword_pf" in select_edismax.xml?
    config.add_search_field('all_fields') do |field|
      field.label = 'Keyword'
      field.solr_parameters = {
        qf: '${qf}',
        pf: '${pf}'
      }
    end

    # TODO: No "call_number_qf/call_number_pf" in select_edismax.xml
    config.add_search_field('call_number') do |field|
      field.solr_parameters = {
        qf: '${call_number_qf}',
        pf: '${call_number_pf}'
      }
    end

    # TODO: No "isbn_issn_pf" in select_edismax.xml (does that matter?)
    config.add_search_field('isbn_issn') do |field|
      field.label = 'ISBN/ISSN'
      field.solr_parameters = {
        qf: '${isbn_issn_qf}',
        pf: '${isbn_issn_pf}'
      }
    end
  end

  # ===========================================================================
  # :section: Blacklight 7 transition
  # ===========================================================================

  protected

  # get_advanced_search_facets
  #
  # @return [Blacklight::Solr::Response]
  #
  # @see BlacklightAdvancedSearch::AdvancedController#get_advanced_search_facets
  #
  # NOTE: Added for blacklight_advanced_search
  # TODO: Re-evaluate after the gem is compatible with Blacklight 7
  #
  def get_advanced_search_facets
    response, _ =
      search_service.search_results do |search_builder|
        search_builder
          .except(:add_advanced_search_to_solr)
          .append(:facets_for_advanced_search_form)
      end
    response
  end

end

__loading_end(__FILE__)

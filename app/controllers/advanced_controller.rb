# NOTE: Added to override the one defined in the Blacklight Advanced Search gem

class AdvancedController < BlacklightAdvancedSearch::AdvancedController
=begin
  blacklight_config.configure do |config|
    # name of Solr request handler, leave unset to use the same one your Blacklight
    # is ordinarily using (recommended if possible)
    # config.advanced_search.qt = 'advanced'

    ##
    # The advanced search form displays facets as a limit option.
    # By default it will use whatever facets, if any, are returned
    # by the Solr request handler in use. However, you can use
    # this config option to have it request other facet params than
    # default in the Solr request handler, in desired.
    config.advanced_search.form_solr_parameters = {}

    # name of key in Blacklight URL, no reason to change usually.
    config.advanced_search.url_key = 'advanced'

    # We are going to completely override the inherited search fields
    config.search_fields.clear

    config.add_search_field 'author' do |field|
      field.solr_local_parameters = {
        :pf => "$pf_author",
        :qf => "$qf_author"
      }
    end

    config.add_search_field 'title' do |field|
      field.solr_local_parameters = {
        :pf => "$pf_title",
        :qf => "$qf_title"
      }
    end

    config.add_search_field 'subject' do |field|
      field.solr_local_parameters = {
        :pf => "$pf_subject",
        :qf => "$qf_subject"
      }
    end

    config.add_search_field 'keyword' do |field|
      field.solr_local_parameters = {
        :pf => "$pf_keyword",
        :qf => "$qf_keyword"
      }
    end

    config.add_search_field 'number' do |field|
      field.solr_local_parameters = {
        :pf => "$pf_number",
        :qf => "$qf_number"
      }
    end
  end
=end

  protected

  # Created to override the method defined in Blacklight Advanced Search.
  #
  # @see BlacklightAdvancedSearch::AdvancedController
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

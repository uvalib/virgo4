# lib/ext/ebsco-eds/eds_override.rb

__loading_begin(__FILE__)

require 'ebsco/eds'

# =============================================================================
# :section: Inject constants into EBSCO::EDS
# =============================================================================

module EBSCO::EDS

  SOLR_SEARCH_TO_EBSCO_FIELD_CODE = {
    author:          'AU',
    subject:         'SU',
    title:           'TI',
    text:            'TX',
    abstract:        'AB',
    source:          'SO',
    issn:            'IS',
    isbn:            'IB',
    descriptor:      'DE', # NOTE: not in EBSCO::EDS:Info
    series:          'SE', # NOTE: not in EBSCO::EDS:Info
    subject_heading: 'SH', # NOTE: not in EBSCO::EDS:Info
    keywords:        'KW', # NOTE: not in EBSCO::EDS:Info
  }.stringify_keys.freeze

  # NOTE: without :eds_search_limiters_facet, :eds_publication_year_range_facet
  SOLR_FACET_TO_EBSCO_FACET = {
    eds_language_facet:             'Language',
    eds_subject_topic_facet:        'SubjectEDS',
    eds_subjects_geographic_facet:  'SubjectGeographic',
    eds_publisher_facet:            'Publisher',
    eds_journal_facet:              'Journal',
    eds_category_facet:             'Category',
    eds_library_location_facet:     'LocationLibrary',
    eds_library_collection_facet:   'CollectionLibrary',
    eds_author_university_facet:    'AuthorUniversity',
    eds_publication_year_facet:     'PublicationYear',
    eds_publication_type_facet:     'SourceType',
    eds_content_provider_facet:     'ContentProvider',
  }.stringify_keys.freeze

end

__loading_end(__FILE__)

# lib/ext/ebsco-eds/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the EBSCO EDS gem.

__loading_begin(__FILE__)

require 'ebsco/eds'

module EBSCO::EDS

  # Mapping of Blacklight facet name to EBSCO Facet.
  #
  # @type [Hash{String=>String}]
  #
  # NOTE: without :eds_search_limiters_facet, :eds_publication_year_range_facet
  #
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

  # Mapping of Solr search field to EBSCO Field Code.
  #
  # @type [Hash{String=>String}]
  #
  # @see https://connect.ebsco.com/s/article/What-Field-Codes-are-available-when-searching-EBSCO-Discovery-Service-EDS
  #
  # == 'AB' - Abstract [word indexed]
  # Performs a keyword search of the abstract summaries.
  #
  # == 'AU' - Author [word indexed]
  # Performs a keyword search for any authors of an article.
  #
  # == 'IB' - ISBN [phrase indexed]
  # Performs an exact search for an article's identification number in the ISBN
  # and EISBN fields.
  #
  # == 'IS' - ISSN [phrase indexed]
  # Performs an exact search for a publication's International Standard Serial
  # Number.
  #
  # == 'SO' - Source (Journal Name) [word indexed]
  # Performs a keyword search for the journal name of the article.
  #
  # == 'SU' - Subject Terms [word indexed]
  # Performs a keyword search of the subject headings listed in records.
  #
  # == 'TX' - All Text [word indexed]
  # Performs a keyword search of all the database's searchable fields.  Using
  # the TX field code will cause the search to look for the keyword in the full
  # text as well as the citation record.
  #
  # == 'TI' - Title [word indexed]
  # Searches keywords in a record's English and non-English title field.
  #
  SOLR_SEARCH_TO_EBSCO_FIELD_CODE = {
    abstract: 'AB',
    author:   'AU',
    isbn:     'IB',
    issn:     'IS',
    source:   'SO',
    subject:  'SU',
    text:     'TX',
    title:    'TI',
  }.stringify_keys.freeze

  # ===========================================================================
  # Search fields
  # ===========================================================================

  # These are field codes that are only meaningful for certain EBSCO databases
  # so they are not included in the active #SOLR_SEARCH_TO_EBSCO_FIELD_CODE
  # table but may be useful for future use in specialized circumstances.
  #
  # NOTE: None of these are referenced in EBSCO::EDS:Info
  #
  # @type [Hash{String=>String}]
  #
  # @see https://connect.ebsco.com/s/article/What-Field-Codes-are-available-when-searching-EBSCO-Discovery-Service-EDS
  #
  # == 'AD' - Author Affiliation [phrase indexed]
  # Performs an exact search for companies or organizations an author is
  # affiliated with, may also include correspondence address.
  # NOTE: Only for Academic Search Premier
  #
  # == 'AF' - Author Affiliation [word indexed]
  # Performs a keyword search for companies or organizations an author is
  # affiliated with, may also include correspondence address.
  # NOTE: Only for Academic Search Premier
  #
  # == 'AN' - Accession Number [phrase indexed]
  # Performs an exact search for an article's unique identification number.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'AR' - Author [phrase indexed]
  # Performs an exact search for an article's author, if available, in the
  # format of "last name, first name, and middle initial".
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'AS' - Author Supplied Abstract [word indexed]
  # Performs a search for the value "Y" indicating that the document
  # contains an author supplied abstract.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'CS' - Cover Story [phrase indexed]
  # Performs an exact search for the value Y or N. Y indicates that the
  # articles will be a cover story.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'CY' - Country ID [phrase indexed] [p,A,M]
  # Performs an exact search for a country's two-character identification
  # code.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'DE' - Subjects Authority [phrase indexed]
  # Performs an exact search for subject headings and author-supplied
  # keywords describing an article.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'DT' - Date of Publication [date indexed]
  # Performs an exact search for the date of publication of an article into
  # the database in "YYYYMMDD" format.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'FM' - Images Available [phrase indexed]
  # Performs an exact search for an article's type of full text. The
  # searchable values are:
  # - 'T' - HTML full text
  # - 'C' - images embedded in the full text
  # - 'P' - PDF document
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'FT' - Full Text Available [phrase indexed]
  # Performs an exact search for the value Y or N.  Y indicates that the
  # records have full text available.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'GE' - Geographic Terms [word indexed]
  # Performs a keyword search of geographic locations pertaining to an
  # article's content.
  # NOTE: Only for Academic Search Premier
  #
  # == 'IL' - Illustrations [word indexed]
  # Performs an exact search for the value Y or N. Y indicates that the
  # articles contain illustrations (e.g. graphs, charts, diagrams, etc.).
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'IP' - Issue [word indexed]
  # Performs an exact search for a publication's issue number.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'JN' - Journal Name [phrase indexed]
  # Performs a keyword search for the journal name of the article.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'KW' - Keywords [word indexed]
  # Performs a keyword search for author-supplied terms describing the
  # article.
  # NOTE: Only for Academic Search Premier
  #
  # == 'LA' - Language [word indexed]
  # Performs a keyword search for the language in which an article was
  # originally published.
  # NOTE: Only for Academic Search Premier
  #
  # == 'LK' - Language of Keywords [word indexed]
  # Performs a keyword search of the language of author-supplied terms
  # describing the article.
  # NOTE: Only for Academic Search Premier
  #
  # == 'MH' - Subjects [word indexed]
  # Performs a keyword search of a document's geographic subject terms,
  # keywords in an article, and generic subject headings.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'PG' - Number of Pages [phrase indexed]
  # Performs an exact search for an article's page count.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'PS' - Reviews & Products [word indexed]
  # Performs a keyword search for products and book reviews within the
  # article's content.
  # NOTE: Only for Academic Search Premier
  #
  # == 'PT' - Publication Type [phrase indexed]
  # Performs an exact search for the publication type.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'PZ' - Document Type [phrase indexed]
  # Performs and exact search for the document type.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'RV' - Peer-Reviewed [phrase indexed]
  # Performs an exact search for the value Y or N. Y indicates that the
  # articles are peer-reviewed.
  # NOTE: Only for Academic Search Premier
  #
  # == 'SH' - Controlled Subject Heading [phrase indexed]
  # Performs an exact search in the controlled index terms assigned to the
  # document from the Subject Thesaurus.
  # NOTE: Only for Academic Search Premier
  #
  # == 'SP' - Start Page [phrase indexed]
  # Performs an exact search for an article's starting page number.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'UI' - Unique Identifier [phrase indexed]
  # Performs an exact search for an article's accession number.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  # == 'VI' - Volume [phrase indexed]
  # Performs an exact search for a publication's volume number.
  # NOTE: Only for Academic Search Premier and MasterFILE Premier
  #
  OTHER_SOLR_SEARCH_TO_EBSCO_FIELD_CODE = {
    abstract_supplied: 'AS',
    accession_number:  'AN',
    affiliation:       'AF',
    affiliation_exact: 'AD',
    all_subjects:      'MH',
    author_exact:      'AR',
    country:           'CY',
    cover_story:       'CS',
    date:              'DT',
    descriptor:        'DE',
    document_type:     'PZ',
    full_text:         'FT',
    geographic_terms:  'GE',
    illustrations:     'IL',
    images:            'FM',
    issue:             'IP',
    journal_name:      'JN',
    keyword:           'KW',
    keyword_language:  'LK',
    language:          'LA',
    pages:             'PG',
    peer_reviewed:     'RV',
    publication_type:  'PT',
    reviews:           'PS',
    series:            'SE',
    start_page:        'SP',
    subject_heading:   'SH',
    unique_identifier: 'UI',
    volume:            'VI',
  }.stringify_keys.freeze

end

require_subdir(__FILE__)

__loading_end(__FILE__)

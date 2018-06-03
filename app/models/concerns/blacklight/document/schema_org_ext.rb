# app/models/concerns/blacklight/document/schema_org_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Override Blacklight::Document::SchemaOrg
#
# Although part of a logical hierarchy, each type is represented in a flat
# namespace.  The root of the hierarchy (most generic type) is "Thing".
#
# Each type has online documentation and formal definitions:
#
#   Canonical URL:          "http://schema.org/Thing"
#   HTML documentation:     "http://schema.org/Thing"
#   RDF/N3 triples:         "http://schema.org/Thing.nt"
#   RDF/XML definition:     "http://schema.org/Thing.rdf"
#   RDF/Turtle definition:  "http://schema.org/Thing.ttl"
#   JSON-LD definition:     "http://schema.org/Thing.jsonld"
#
# @see https://schema.org
# @see https://schema.org/docs/full.html
# @see https://schema.org/docs/developers.html
# @see https://www.w3.org/community/schemabibex
#
module Blacklight::Document::SchemaOrgExt

  include Blacklight::Document::SchemaOrg

  BASE = 'http://schema.org'

  # ===========================================================================
  # :section: Blacklight::Solr::SchemaOrg overrides
  # ===========================================================================

  public

  # itemtype
  #
  # @return [String]
  #
  # == Implementation Notes
  # The including class should override this method as needed.
  #
  def itemtype(*)
    SCHEMA_ORG[:CreativeWork]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a hash from a string comprised of newline-delimited lines.
  #
  # @param [String] lines
  #
  # @return [Hash{Symbol=>String}]
  #
  def self.make_hash(lines)
    lines.to_s
      .gsub(/^[ \t]+/, '') # Remove leading spaces.
      .gsub(/#.*$/,    '') # Remove comments following "#".
      .gsub(/[ \t]+$/, '') # Remove trailing spaces.
      .split("\n")
      .map { |name| [name.to_sym, "#{BASE}/#{name}".freeze] if name.present? }
      .compact
      .to_h
  end

  SCHEMA_ORG = make_hash(<<-EOF).freeze
    Thing

      # Things of these types might be relevant for labeling action buttons
      # (e.g. ListenAction, ReadAction, etc).
      Action

      # This of these types are products of intellectual output.  Some of them
      # are relevant for denoting a search result entry type; others would be
      # more appropriate for markup of metadata fields.
      CreativeWork
        Article                       # Default for EBSCO entries
          AdvertiserContentArticle    # (extension)
          NewsArticle                 # EBSCO entry type
            AnalysisNewsArticle       # (extension)
            BackgroundNewsArticle     # (extension)
            OpinionNewsArticle        # (extension)
            ReportageNewsArticle      # (extension)
            ReviewNewsArticle         # (extension) (also under CriticReview)
          Report                      # EBSCO entry type
          SatiricalArticle            # (extension)
          ScholarlyArticle            # EBSCO entry type
            MedicalScholarlyArticle   # (extension)
          SocialMediaPosting
            BlogPosting
              LiveBlogPosting
            DiscussionForumPosting
          TechArticle
            APIReference
        Atlas                         # (extension) Solr entry type
        Blog
        Book                          # Solr entry type
          Audiobook                   # (extension)
        CategoryCodeSet               # (extension)
        Chapter                       # (extension)
        Clip                          # Metadata fields
          MovieClip
          RadioClip
          TVClip
          VideoGameClip
        Collection                    # (extension) Solr entry type
        ComicStory                    # (extension)
        Comment
          Answer
        Conversation
        Course
        CreativeWorkSeason            # Metadata fields
          RadioSeason
          TVSeason
        CreativeWorkSeries            # Metadata fields
          BookSeries
          MovieSeries
          Periodical
            ComicSeries               # (extension)
            Newspaper                 # (extension) Solr entry type
          RadioSeries
          TVSeries
          VideoGameSeries
        DataCatalog                   # Many/most Data-Planet entries
        Dataset                       # Solr entry type
          DataFeed
            CompleteDataFeed          # (extension)
        Diet                          # (extension)
        DigitalDocument
          NoteDigitalDocument
          PresentationDigitalDocument
          SpreadsheetDigitalDocument
          TextDigitalDocument
        Episode                       # Metadata fields
          RadioEpisode
          TVEpisode
        ExercisePlan                  # (extension)
        Game
          VideoGame                   # (also under SoftwareApplication)
        HowTo
          Recipe
        Legislation                   # (extension)
          LegislationObject           # (extension)
        Map                           # Solr entry type
        MediaObject                   # Embedded object
          AudioObject
          DataDownload
          ImageObject
            Barcode
          MusicVideoObject
          VideoObject
        Menu
          MenuSection
        Message
          EmailMessage
        Movie                         # Solr entry type
        MusicComposition
        MusicPlaylist
          MusicAlbum
          MusicRelease
        MusicRecording                # Solr entry type
        Painting
        Photograph                    # Solr entry type
        PublicationIssue
          ComicIssue                  # (extension)
        PublicationVolume
        Question
        Quotation
        Review                        # EBSCO article type
          ClaimReview
          CriticReview                # (extension)
          EmployerReview              # (extension)
          UserReview                  # (extension)
        Sculpture
        Series
        SoftwareApplication
          MobileApplication
          WebApplication
        SoftwareSourceCode
        Thesis                        # Solr entry type
        VisualArtwork
          CoverArt                    # (extension)
            ComicCoverArt             # (extension) (also under ComicStory)
        WebPage                       # Page markup on <body>
          AboutPage                   # Page markup - About, Terms-of-use
          CheckoutPage                # Page markup - Bookmarks
          CollectionPage              # Page markup - item show page
            ImageGallery
            VideoGallery
          ContactPage
          ItemPage                    # Page markup - item show page
          MedicalWebPage              # (extension)
          ProfilePage                 # Page markup - My Account
          QAPage
          SearchResultsPage           # Page markup - search results
        WebPageElement                # Page markup on interior elements
          SiteNavigationElement       # Page markup - navbar
          Table
          WPAdBlock
          WPFooter                    # Page markup - page footer
          WPHeader                    # Page markup - page header
          WPSideBar                   # Page markup - facets
        WebSite                       # Solr entry type

      # Might be relevant for some metadata fields (e.g. EducationEvent for a
      # conference location and dates, Rating for a movie's released rating).
      Event
      Intangible
      MedicalEntity                   # (extension)
      Organization
      Person
      Place
      Product
  EOF

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ModuleMethods

    # Normalize the keys for mappings so that comparisons can be done without
    # regard to spaces, punctuation or case.
    #
    # @param [String, Symbol] key
    #
    # @return [String]
    #
    def itemtype_key(key)
      key.to_s.gsub(/\s|[[:punct:]]/, '').downcase.to_sym
    end

    # Maps normalized field values to the associated key in #itemtype_table.
    #
    # @param [Hash] hash
    #
    # @return [Hash{String=>Symbol}]
    #
    def itemtype_mapping(hash)
      hash.map { |k, v| [itemtype_key(k), v] }.to_h
    end

    # Perform a lookup of a *mapping* (created via #itemtype_mapping) based on
    # the metadata value accessed through the given metadata *field*.
    #
    # @param [Hash]   mapping
    # @param [Symbol] field
    #
    # @return [Symbol, nil]
    #
    # == Usage Notes
    # This method expects to be called from a Blacklight::Document so that
    # `self[field]` is the metadata addressed by *field*.
    #
    def itemtype_lookup(mapping, field)
      keys = Array.wrap(self[field]).map { |k| itemtype_key(k) }
      case keys.size
        when 0 then return
        when 1 then mapping[keys.first]
        else        mapping.find { |k, v| return v if keys.include?(k) }
      end
    end

    # Symbolized names of Schema.org items with their canonical values.
    #
    # @return [Hash{Symbol=>String}]
    #
    def itemtype_table
      Blacklight::Document::SchemaOrgExt::SCHEMA_ORG
    end

  end

  include ModuleMethods
  extend  ModuleMethods

end

__loading_end(__FILE__)

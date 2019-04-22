# app/models/ils_availability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/catalog_item'
require 'ils/home_library'

# IlsAvailability
#
# @attr [Ils::CatalogItem] catalog_item
#
class IlsAvailability < Ils::Message

  schema do

    has_one :catalog_item

  end

  include Ils::LibraryMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [SolrDocument]
  attr_accessor :document

  # @return [Array<Ils::HomeLibrary>]
  attr_reader :libraries

  # @return [Hash{String=>String}]
  attr_reader :lost

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [SolrDocument] :doc
  # @option options [Hash]         :lost
  # @option options [Symbol]       :format
  #
  # This method overrides:
  # @see Ils::Record::Base#initialize
  #
  def initialize(data, **opt)
    opt = opt.dup
    @document  = opt.delete(:doc)  || abort('Missing doc parameter')
    @lost      = opt.delete(:lost) || {}
    @libraries = []
    super(data, opt)
    self.catalog_item.document = @document
    set_summary_holdings
    weed_holdings
  end

  delegate_missing_to :catalog_item

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # linkable_to_ilink?
  #
  def linkable_to_ilink?
    !document.pda?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # Indicates whether the given user has this ckey and call number checked out.
  #
  # @param [::User, Ils::User] user
  # @param [String, nil]       call_number
  #
  def user_has_checked_out?(user, call_number = nil)
    account =
      case user
        when Ils::User then user
        when ::User    then user.account
      end
    return unless account.present?
    if call_number.blank?
      call_numbers = holdable_call_numbers
      call_number = call_numbers.first if call_numbers.size == 1
    end
    account.checkouts.any? do |checkout|
      next unless checkout.catalog_item.key == catalog_item.key
      checkout.catalog_item.holdings.any? do |holding|
        holding.call_number == call_number
      end
    end
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Order the libraries.
  #
  # @return [Array<Ils::HomeLibrary>]
  #
  def summary_libraries
    @summary_libraries ||=
      begin
        later_summaries = empty_holdings_map
        first_summaries =
          libraries.map { |library|
            deferred = later_library(library.label)
            later_summaries[deferred] << library if deferred
            library unless deferred
          }.compact.sort_by(&:name)
        first_summaries + later_summaries.values.flatten(1).compact
      end
  end

  # Indicate whether the catalog entry is for a title that is only online.
  #
  # In this case availability/holdings information would not be displayed for
  # the entry (despite the fact that it comes from the ILS) because it is
  # always available through its URL.
  #
  def online_only?
    library_copies_available.blank? && lost.blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # holdings
  #
  # @return [Array<Ils::Holding>]
  #
  # @see #set_holdings
  #
  def holdings
    @holdings ||= set_holdings
  end

  # special_collections_holdings
  #
  # @return [Array<Ils::Holding>]
  #
  # @see Ils::Holding#special_collections?
  #
  def special_collections_holdings
    holdings.select(&:special_collections?)
  end

  # Table of libraries and copies.
  #
  # @return [Hash{String=>Array<Ils::Copy>}]
  #
  def library_copies
    @library_copies ||=
      Hash.new.tap do |result|
        holdings.each do |holding|
          library = holding.library.label
          result[library] ||= []
          result[library] += holding.copies
        end
      end
  end

  # Table of libraries and available copies.
  #
  # @return [Hash{String=>Array<Ils::Copy>}]
  #
  def library_copies_available
    @library_copies_available ||=
      library_copies.map { |lib, copies|
        copies = copies.select(&:available?)
        [lib, copies] if copies.present?
      }.compact.to_h
  end

  # Table of libraries and unavailable copies.
  #
  # @return [Hash{String=>Array<Ils::Copy>}]
  #
  def library_copies_unavailable
    @library_copies_unavailable ||=
      library_copies.map { |lib, copies|
        copies = copies.select(&:unavailable?)
        [lib, copies] if copies.present?
      }.compact.to_h
  end

  # Table of the number of non-shadowed copies at each library.
  #
  # @return [Hash{String=>Integer}]
  #
  def library_copy_counts
    @library_copy_counts ||=
      library_copies.map { |lib, copies| [lib, copies.size] }.to_h
  end

  # Table of the number of available copies at each library.
  #
  # @return [Hash{String=>Integer}]
  #
  def library_available_counts
    @library_available_counts ||=
      library_copies_available.map { |lib, copies| [lib, copies.size] }.to_h
  end

  # Table of the number of unavailable copies at each library.
  #
  # @return [Hash{String=>Integer}]
  #
  def library_unavailable_counts
    @library_unavailable_counts ||=
      library_copies_unavailable.map { |lib, copies| [lib, copies.size] }.to_h
  end

  # Table of libraries and locations.
  #
  # @return [Hash{String=>Array<String>}]
  #
  def library_locations
    @library_locations ||=
      library_copies.map { |lib, copies|
        [lib, copies.map { |copy| copy.location.label }.uniq]
      }.to_h
  end

  # Table of libraries and locations at which the title is available.
  #
  # @return [Hash{String=>Array<String>}]
  #
  def library_locations_available
    @library_locations_available ||=
      library_copies_available.map { |lib, copies|
        [lib, copies.map { |copy| copy.location.label }.uniq]
      }.to_h
  end

  # Table of libraries and locations at which the title is available.
  #
  # @return [Hash{String=>Array<String>}]
  #
  def library_locations_unavailable
    @library_locations_unavailable ||=
      library_copies_unavailable.map { |lib, copies|
        [lib, copies.map { |copy| copy.location.label }.uniq]
      }.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Sort and finalize holdings.
  #
  # @return [Array<Ils::Holding>]
  #
  def set_holdings
    later_holdings = empty_holdings_map
    first_holdings =
      catalog_item.holdings.map { |holding|
        deferred = later_library(holding.library.code)
        later_holdings[deferred] << holding if deferred
        holding unless deferred
      }.compact

    # Sort by library and shelving key (reverse sort for journals).
    if document.journal?
      first_holdings.sort! do |a, b|
        (a.library.label <=> b.library.label).nonzero? ||
          (b.shelving_key <=> a.shelving_key)
      end
      later_holdings.each { |_, h| h.sort_by!(&:shelving_key).reverse! }
    else
      first_holdings.sort_by! { |h| [h.library.label, h.shelving_key] }
      later_holdings.each { |_, h| h.sort_by!(&:shelving_key) }
    end

    first_holdings + later_holdings.values.flatten.compact
  end

  # Generate an empty holdings map.
  #
  # @return [Hash{Symbol=>Array}]
  #
  def empty_holdings_map
    later_libraries.map { |lib| [lib, []] }.to_h
  end

  # ===========================================================================
  # :section: Initialization
  # ===========================================================================

  protected

  # Parse the Solr record for summary holdings -
  # build into: Library => HomeLocations => Summaries
  #
  # @return [void]
  #
  # == Implementation Notes
  # The Solr :summary_holdings_display field has this format:
  #
  #   library | location | text | note | optional label | call number info
  #
  def set_summary_holdings
    document.values(:summary_holdings_a).each do |value|
      lib, loc, text, note, _label, call_number = value.split('|')
      next if lib.blank? || loc.blank?
      library = find_library(lib) || add_library(lib)
      library.add_summary_line(loc, call_number, text, note) if library
    end
  end

  # Strip the received catalog holdings information of hidden and shadowed
  # holdings.
  #
  # @return [void]
  #
  def weed_holdings
    barcodes = document.barcodes.presence
    catalog_item.holdings.tap do |holdings|

      # Discard shadowed holdings.
      holdings.delete_if do |holding|
        holding.shadowed? || holding.call_number.upcase.include?('VOID')
      end

      # Discard hidden copies.
      holdings.each do |holding|
        library = holding.library.label
        copies  = holding.copies
        copies.delete_if(&:shadowed?)
        copies.delete_if { |copy|
          (@lost[library] ||= []) << copy if copy.missing? || copy.lost?
        }
        copies.delete_if(&:hidden?)
        copies.keep_if { |copy| barcodes.include?(copy.barcode) } if barcodes
      end

      # Discard holdings with no unhidden copies.
      holdings.delete_if(&:blank?)

      # Reduce notations of lost/missing copies.
      @lost =
        @lost.map { |library, copies|
          next unless copies.present?
          missing = copies.count(&:missing?)
          lost    = copies.size - missing
          note =
            if missing.nonzero? && lost.nonzero?
              "#{missing} missing; #{lost} lost"
            elsif missing > 1
              "#{missing} missing"
            elsif lost > 1
              "#{lost} lost"
            elsif missing
              'missing'
            elsif lost
              'lost'
            end
          [library, note]
        }.compact.to_h

    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Find a library entry.
  #
  # @param [String] name
  #
  # @return [Ils::HomeLibrary]        The library entry.
  # @return [nil]                     If *name* could not be found.
  #
  def find_library(name)
    libraries.find { |lib| lib.identifier?(name) }
  end

  # Add a library entry.
  #
  # @param [String]    name
  # @param [Hash, nil] opt
  #
  # @return [Ils::HomeLibrary]        The new library entry.
  #
  def add_library(name, **opt)
    Ils::HomeLibrary.new(name: name, **opt).tap do |lib|
      libraries << lib
    end
  end

end

__loading_end(__FILE__)

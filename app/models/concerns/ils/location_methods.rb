# app/models/concerns/ils/location_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/common'

# Ils::LocationMethods
#
module Ils::LocationMethods

  include Ils::Common
  extend  Ils::Common

  HOLD_LOCATIONS      = codes /HOLD/
  RESERVE_LOCATIONS   = codes /RESV/, /RSRV/, /RESERVE/, 'PATFAMCOLL'
  REFERENCE_LOCATIONS = codes /REF/,  'FA-SLIDERF'
  DESK_LOCATIONS      = codes /DESK/, 'SERV-DSK'
  NON_CIRC_LOCATIONS  = (REFERENCE_LOCATIONS + DESK_LOCATIONS).freeze

  # An individual item (i.e. "copy") should be included in the availability
  # table if its current location matches one of these Sirsi location codes.
  #
  # @type [Array<String, Regexp>]
  #
  # @see #hidden?
  #
  HIDDEN_LOCATIONS =
    codes(/LOST/, <<~HEREDOC.split)
      UNKNOWN
      MISSING
      DISCARD
      WITHDRAWN
      BARRED
      BURSARED
      INTERNET
      ORD-CANCLD
    HEREDOC

  # An individual item (i.e. "copy") should not normally be represented as
  # "available" if its current location matches one of these Sirsi location
  # codes.
  #
  # @type [Array<String, Regexp>]
  #
  # @see Ils::Copy#available?
  #
  UNAVAILABLE_LOCATIONS =
    codes(HOLD_LOCATIONS, HIDDEN_LOCATIONS, <<~HEREDOC.split)
      CHECKEDOUT
      ON-ORDER
      BINDERY
      INTRANSIT
      ILL
      CATALOGING
      PRESERVATN
      EXHIBIT
      GBP
    HEREDOC

  # An item is part of the "medium-rare workflow" if its home location matches
  # one of these Sirsi LOCATION codes.
  #
  # @type [Array<String, Regexp>]
  #
  # @see Ils::Copy#available?
  #
  MEDIUM_RARE_LOCATIONS = codes 'LOCKEDSTKS'

  # ===========================================================================
  # :section: Ils::Location "mixins"
  # ===========================================================================

  public

  # Indicate whether the given identifier matches the location instance.
  #
  # @param [String] s
  #
  def identifier?(s)
    s = s.to_s.downcase
    [id, name, code].find { |v| v.to_s.downcase == s }.present?
  end

  # A label for the location that may take up less room than the full name.
  #
  # @return [String]
  #
  # == Implementation Notes
  # For consistency with Ils::LibraryMethods#label.
  #
  def label
    name
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # lost?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def lost?(loc = nil)
    match?((loc || code), /LOST/)
  end

  # missing?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def missing?(loc = nil)
    match?((loc || code), 'MISSING')
  end

  # suppressed?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def suppressed?(loc = nil)
    match?((loc || code), 'BARRED')
  end

  # hidden?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # @see Ils::Common#HIDDEN_LOCATIONS
  #
  def hidden?(loc = nil)
    match?((loc || code), HIDDEN_LOCATIONS)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # by_request?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # === Implementation Notes
  # This was an addition to the catalog locations that was introduced to deal
  # with Clemons items that were temporarily moved in the summer of 2018 so
  # they could be requested via the ILLiad IVY queue.
  #
  def by_request?(loc = nil)
    match?((loc || code), 'BY-REQUEST')
  end

  # medium_rare?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # === Usage Notes
  # For items in Ivy with a special workflow.
  #
  # @see Ils::Common#MEDIUM_RARE_LOCATIONS
  # @see UVA::Helper::Library#WORKFLOW_STATUS
  #
  def medium_rare?(loc = nil)
    match?((loc || code), MEDIUM_RARE_LOCATIONS)
  end

  # deans_office?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # @see UVA::Helper::Library#WORKFLOW_STATUS
  #
  def deans_office?(loc = nil)
    match?((loc || code), 'DEANOFFICE')
  end

  # is_ivy?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def is_ivy?(loc = nil)
    match?((loc || code), /IVY/)
  end

  # ivy_annex?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def ivy_annex?(loc = nil)
    match?((loc || code), 'IVYANNEX')
  end

  # ivy_stacks?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # @see self#is_ivy?
  #
  def ivy_stacks?(loc = nil)
    if is_ivy?(loc)
      !ivy_annex?(loc) && !sc_ivy?(loc)
    else
      medium_rare?(loc) || by_request?(loc)
    end
  end

  # sc_ivy?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def sc_ivy?(loc = nil)
    match?((loc || code), 'SC-IVY')
  end

  # not_ordered?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def not_ordered?(loc = nil)
    match?((loc || code), 'NOTORDERED')
  end

  # on_reserve?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  # @see Ils::Common#RESERVE_LOCATIONS
  #
  def on_reserve?(loc = nil)
    match?((loc || code), RESERVE_LOCATIONS)
  end

  # pending?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def pending?(loc = nil)
    match?((loc || code), 'ON-ORDER', 'IN-PROCESS')
  end

  # in_process?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def in_process?(loc = nil)
    match?((loc || code), 'SC-IN-PROC', 'IN-PROCESS')
  end

  # in_transit?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def in_transit?(loc = nil)
    match?((loc || code), 'INTRANSIT')
  end

  # sc_exhibit?
  #
  # @param [String, nil] loc        Default: `code`.
  #
  def sc_exhibit?(loc = nil)
    match?((loc || code), 'DEC-IND-RM')
  end

end

__loading_end(__FILE__)

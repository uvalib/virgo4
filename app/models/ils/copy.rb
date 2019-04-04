# app/models/ils/copy.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/current_location'
require 'ils/home_location'
require 'ils/item_type'

# Ils::Copy
#
# @attr [Integer] copy_number
# @attr [String]  barcode
# @attr [Boolean] shadowed
# @attr [Boolean] current_periodical
#
# @attr [Date]    last_checkout
# @attr [String]  circulate
#
# @attr [Ils::CurrentLocation] current_location
# @attr [Ils::HomeLocation]    home_location
# @attr [Ils::ItemType]        item_type
#
# @see Ils::LocationMethods
# @see Ils::ItemMethods
#
class Ils::Copy < Ils::Record::Base

  schema do

    attribute :copy_number,         Integer
    attribute :barcode,             String, as: 'barCode'
    attribute :shadowed,            Boolean
    attribute :current_periodical,  Boolean

    has_one   :last_checkout,       Date
    has_one   :circulate,           String

    has_one   :current_location
    has_one   :home_location
    has_one   :item_type

  end

  include Ils::LocationMethods
  include Ils::ItemMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # For use with ScUserRequest # TODO
  # @return [String]
  attr_accessor :description

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         opt
  #
  def initialize(data = nil, **opt)
    opt = opt.dup
    @description = opt.delete(:description)
    super(data, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # shadowed?
  #
  def shadowed?
    shadowed.present?
  end

  # current_periodical?
  #
  def current_periodical?
    current_periodical
  end

  # last_checkout_f
  #
  def last_checkout_f
    date_format(last_checkout)
  end

  # circulates?
  #
  def circulates?
    circulate.match?(/[YM]/)
  end

  # A short-hand for #current_location
  #
  # @return [Ils::CurrentLocation]
  #
  def location
    current_location
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # This definition exists so that LocationMethods are defined in terms of
  # the current_location code for this copy.
  #
  # @return [String]
  #
  def code
    current_location.code
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # medium_rare?
  #
  # @see LocationMethods#medium_rare?
  #
  def medium_rare?
    home_location.medium_rare?
  end

  # deans_office?
  #
  # @see LocationMethods#deans_office?
  #
  def deans_office?
    home_location.deans_office?
  end

  # is_ivy?
  #
  # @see LocationMethods#is_ivy?
  #
  def is_ivy?
    home_location.is_ivy? || current_location.is_ivy?
  end

  # ivy_annex?
  #
  # @see LocationMethods#ivy_annex?
  #
  def ivy_annex?
    home_location.ivy_annex? || current_location.ivy_annex?
  end

  # ivy_stacks?
  #
  # @see LocationMethods#ivy_stacks?
  #
  def ivy_stacks?
    home_location.ivy_stacks? || current_location.ivy_stacks?
  end

  # sc_ivy?
  #
  # @see LocationMethods#sc_ivy?
  #
  def sc_ivy?
    home_location.sc_ivy? || current_location.sc_ivy?
  end

  # ===========================================================================
  # :section: Ils::ItemMethods overrides
  # ===========================================================================

  public

  # Indicate whether the item is a periodical or journal.  (For ordered lists
  # of items, these are sorted in reverse order.)
  #
  # This method overrides Ils::ItemMethods#journal?
  #
  def journal?(*)
    super(item_type.code)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this is a copy that can appear in holdings lists.
  #
  def visible?
    !shadowed?
  end

  # Indicate whether this is a copy that exists somewhere in the library
  # system (as opposed to a copy that could be ordered) and is not hidden.
  #
  def exists?
    !(shadowed? || not_ordered? || pending?)
  end

  # Indicate whether this is a copy that can be used by a patron.
  #
  # @see #unavailable?
  #
  def available?
    !unavailable? unless shadowed?
  end

  # Indicate whether this is a copy that cannot be used by a patron.
  #
  # IN-PROCESS items whose home is the special collections in Ivy should be
  # considered available.  IN-PROCESS items whose home location is anywhere
  # else should be considered unavailable.
  #
  # @see Ils::Common#UNAVAILABLE_LOCATIONS
  #
  def unavailable?
    return if shadowed?
    unavailable = UNAVAILABLE_LOCATIONS
    unavailable += %w(IN-PROCESS) unless home_location.sc_ivy?
    match?(current_location.code, unavailable)
  end

end

__loading_end(__FILE__)

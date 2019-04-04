# app/models/ils/user.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/hold'
require 'ils/course'
require 'ils/checkout'

# Ils::User
#
# @attr [String]  key
# @attr [String]  sirsi_id
# @attr [String]  computing_id
#
# @attr [Boolean] barred
# @attr [Boolean] bursarred
# @attr [Boolean] delinquent
# @attr [String]  display_name
# @attr [String]  email
# @attr [Integer] library_group
# @attr [String]  organizational_unit
# @attr [Integer] preferred_language
# @attr [String]  profile
# @attr [Integer] checkout_count
# @attr [Integer] hold_count
# @attr [Integer] overdue_count
# @attr [Integer] reserve_count
# @attr [Integer] recalled_count
# @attr [String]  physical_delivery
# @attr [String]  description
# @attr [String]  first_name
# @attr [String]  middle_name
# @attr [String]  last_name
# @attr [Integer] status_id
# @attr [String]  telephone
# @attr [String]  title
# @attr [String]  pin
#
# @attr [Array<String>] groups
#
# @attr [Array<Ils::Hold>]     holds
# @attr [Array<Ils::Course>]   courses
# @attr [Array<Ils::Checkout>] checkouts
#
class Ils::User < Ils::Record::Base

  schema do

    attribute :key,                 String
    attribute :sirsi_id,            String
    attribute :computing_id,        String

    has_one   :barred,              Boolean
    has_one   :bursarred,           Boolean
    has_one   :delinquent,          Boolean
    has_one   :display_name,        String
    has_one   :email,               String
    has_one   :library_group,       Integer
    has_one   :organizational_unit, String    # from LDAP
    has_one   :preferred_language,  Integer,  as: 'preferredlanguage'
    has_one   :profile,             String    # from Sirsi
    has_one   :checkout_count,      Integer,  as: 'totalCheckouts'
    has_one   :hold_count,          Integer,  as: 'totalHolds'
    has_one   :overdue_count,       Integer,  as: 'totalOverdue'
    has_one   :reserve_count,       Integer,  as: 'totalReserves'
    has_one   :recalled_count,      Integer,  as: 'totalRecalls'
    has_one   :physical_delivery,   String
    has_one   :description,         String    # from LDAP
    has_one   :first_name,          String,   as: 'givenName'
    has_one   :middle_name,         String,   as: 'initials'
    has_one   :last_name,           String,   as: 'surName'
    has_one   :status_id,           Integer
    has_one   :telephone,           String
    has_one   :title,               String
    has_one   :pin,                 String

    has_many  :groups,              String

    has_many  :holds
    has_many  :courses
    has_many  :checkouts

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # faculty?
  #
  def faculty?
    profile.match?(/^Faculty/i) || ldap_faculty?
  end

  # instructor?
  #
  def instructor?
    profile.match?(/^Instructor/i) || ldap_instructor?
  end

  # staff?
  #
  def staff?
    profile.match?(/^Staff|Employee/i) || ldap_staff?
  end

  # graduate?
  #
  def graduate?
    profile.match?(/^Grad/i) || ldap_graduate?
  end

  # undergraduate?
  #
  def undergraduate?
    profile.match?(/^Undergrad/i) || ldap_undergraduate?
  end

  # continuing_ed?
  #
  def continuing_ed?
    profile.match?(/^Continuing\s+Ed/i) || ldap_continuing_ed?
  end

  # RESEARCHERS don't have a profile, but they shouldn't have a U.Va.
  # computing id.
  #
  def virginia_borrower?
    # @profile !~ /^[a-z]{2,3}([0-9][a-z]{1,2})?$/i
    profile.match?(/Virginia Borrower|Other VA Faculty|Alum/i) ||
      profile.blank?
  end

  # ldap_faculty?
  #
  def ldap_faculty?
    description.match?(/^Faculty/i)
  end

  # ldap_instructor?
  #
  def ldap_instructor?
    description.match?(/^Instructor/i)
  end

  # ldap_staff?
  #
  def ldap_staff?
    description.match?(/^Staff|Employee/i)
  end

  # ldap_graduate?
  #
  def ldap_graduate?
    description.match?(/^Grad/i)
  end

  # ldap_undergraduate?
  #
  def ldap_undergraduate?
    description.match?(/^(Undergrad|ugrad)/i)
  end

  # ldap_continuing_ed?
  #
  def ldap_continuing_ed?
    description.match?(/^Continuing\s+Ed/i)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # barred?
  #
  def barred?
    barred
  end

  # Indicate whether the user can make LEO requests.
  #
  def can_use_leo?
    faculty?
  end

  # Indicate whether the user can make Interlibrary Loan requests.
  #
  def can_use_ill?
    !virginia_borrower?
  end

  # Indicate whether the user can place items on course reserve.
  #
  def can_make_reserves?
    !undergraduate? && !virginia_borrower?
  end

  # Indicate whether the user can recommend an item for purchase.
  #
  def can_request_purchase?
    true # TODO: Should this be !virginia_borrower? ?
  end

  # Indicate whether the user can request item scanning.
  #
  def can_request_scanning?
    true # TODO: Should this be !virginia_borrower? ?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # sorted_holds
  #
  # @return [Array<Ils::Hold>]
  #
  def sorted_holds
    holds.sort_by { |a| [a.date_placed, a.catalog_item.title] }
  end

  # sorted_courses
  #
  # @return [Array<Ils::Course>]
  #
  def sorted_courses
    courses.sort_by(&:code)
  end

  # sorted_checkouts
  #
  # @return [Array<Ils::Checkout>]
  #
  def sorted_checkouts
    checkouts.sort_by { |a| [a.date_charged, a.catalog_item.title] }
  end

end

__loading_end(__FILE__)

# app/models/ils_patron.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/user'

# IlsPatron
#
# @attr [Ils::User] user
#
class IlsPatron < Ils::Message

  schema do

    has_one :user

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [Symbol] :format
  #
  def initialize(data, **opt)
    data = strip_ldap_prefixes(data)
    super(data, opt)
    self.user = Ils::User.new(nil, error: exception) if error?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # LDAP has begun to add prefixes to certain fields.
  #
  # @param [String, Hash] data
  #
  # @param [String]
  #
  # @see https://virginia.service-now.com/its?id=itsweb_kb_article&sys_id=770cb59adb3093c44f32fb671d96199d
  #
  def strip_ldap_prefixes(data)
    case data
      when Hash   then data.map { |k, v| [k, strip_ldap_prefixes(v) ] }.to_h
      when String then data.gsub(/[EUSW]\d:/, '')
      else             data
    end
  end

end

__loading_end(__FILE__)

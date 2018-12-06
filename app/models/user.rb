# app/models/user.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# User
#
# @see Blacklight::User
# @see Devise::Models
#
class User < ApplicationRecord

  # Connects this user object to bookmarks and searches.
  include Blacklight::User

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # ===========================================================================
  # :section: Blacklight::User overrides
  # ===========================================================================

  public

  # Overrides the Blacklight method which arbitrarily uses the document type
  # of the first of *docs* as a database query criterion.  This method just
  # uses the document IDs for the database query.
  #
  # @param [Array<Blacklight::Document>, nil] docs
  #
  # @return [Array<ActiveRecord>]
  #
  # This method overrides
  # @see Blacklight::User#bookmarks_for_documents
  #
  def bookmarks_for_documents(docs = nil)
    bookmarks_for(docs)
  end

  # ===========================================================================
  # :section: Object overrides
  # ===========================================================================

  public

  # Method added by Blacklight; Blacklight uses #to_s on your user class to get
  # a user-displayable login/identifier for the account.
  #
  # @return [String]
  #
  def to_s
    email
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Virgo 3 expects this as the user's ID.
  #
  # @return [String]
  #
  def login
    email.to_s.sub(/@.*/, '')
  end

  # Return the user's bookmarks for the given item(s).
  #
  # @param [Array<Blacklight::Document>] docs
  #
  # @return [Array<ActiveRecord>]
  #
  def bookmarks_for(*docs)
    ids = docs.flatten.compact.map(&:id).presence
    ids ? bookmarks.where(document_id: ids) : []
  end

end

__loading_end(__FILE__)

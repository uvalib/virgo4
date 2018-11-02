# app/models/bookmark.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This extends the model defined in the Blacklight gem to include the added
# :lens column.
#
class Bookmark < ApplicationRecord

  belongs_to :user,     polymorphic: true
  belongs_to :document, polymorphic: true

  validates  :user_id,  presence: true

  def document
    document_type.new(document_type.unique_key => document_id)
  end

  def document_type
    value = super if defined?(super)
    value &&= value.constantize
    value ||= default_document_type
  end

  def default_document_type
    SolrDocument
  end

end

__loading_end(__FILE__)

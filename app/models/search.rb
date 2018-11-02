# app/models/search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# This extends the model defined in the Blacklight gem to add a method for
# extracted relevant query parameters.
#
class Search < ApplicationRecord

  belongs_to :user, optional: true, polymorphic: true

  serialize  :query_params

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # A Search instance is considered a saved search if it has a user_id.
  #
  def saved?
    user_id.present?
  end

  # Delete old, unsaved searches.
  #
  # @param [Numeric] days_old
  #
  def self.delete_old_searches(days_old)
    if !days_old.is_a?(Numeric)
      raise ArgumentError, 'days_old is expected to be a number'
    elsif days_old <= 0
      raise ArgumentError, 'days_old is expected to be greater than 0'
    end
    cut_off = Time.zone.today - days_old
    self.where(['created_at < ? AND user_id IS NULL', cut_off]).destroy_all
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The :query_params sorted by key.
  #
  # @return [Hash]
  #
  def sorted_query
    fields = query_params || {}
    fields.sort_by { |k, v| "#{k} #{sorted(v)}" }.to_h.with_indifferent_access
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Sort an item.
  #
  # @param [Object] item
  #
  def sorted(item)
    case item
      when Hash  then item.sort_by { |k, v| "#{k} #{sorted(v)}" }
      when Array then item.map { |i| sorted(i) }.join('/')
      else            item
    end
  end

end

__loading_end(__FILE__)

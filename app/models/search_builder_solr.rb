# app/models/search_builder_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'search_builder'

# This variant of SearchBuilder contains definitions for processor filter
# methods that may be assigned to the #search_builder_processors array in the
# configuration for a lens to define the type of searches the lens can perform.
#
# @see SearchBuilder
#
class SearchBuilderSolr < SearchBuilder

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Eliminate shadowed records via solr_params[:fq].
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  # NOTE: This is not yet in the Virgo4 Solr index.
  #
  def public_only(solr_params)
    add_to_fq!(solr_params, '-shadowed_location_f:HIDDEN')
  end

  # Include shadowed records via solr_params[:fq].
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  # NOTE: This is not yet in the Virgo4 Solr index.
  #
  def include_hidden(solr_params)
    remove_from_fq!(solr_params, '-shadowed_location_f:HIDDEN')
  end

  # Special parameters to exclude UNDISCOVERABLE records in normal searches
  # (but not advanced searches, or searches for which a collection facet has
  # been selected).
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  # NOTE: This is not yet in the Virgo4 Solr index.
  #
  def discoverable_only(solr_params)
    add_to_fq!(solr_params, '-shadowed_location_f:UNDISCOVERABLE')
  end

  # Include undiscoverable records via solr_params[:fq].
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  # NOTE: This is not yet in the Virgo4 Solr index.
  #
  def include_undiscoverable(solr_params)
    remove_from_fq!(solr_params, '-shadowed_location_f:UNDISCOVERABLE')
  end

  # Select records that include Music in the library facet.
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  def music_library(solr_params)
    add_to_fq!(solr_params, library_f: 'Music')
  end

  # Select records that include Video in the format facet.
  #
  # @param [Hash] solr_params         To be sent to Solr (via RSolr)
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  def video_format(solr_params)
    add_to_fq!(solr_params, format_f: 'Video')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Add terms to solr_params[:fq], creating it if necessary.
  #
  # The effect is to limit to the results to items which match all of the
  # criteria.
  #
  # @param [Hash]               solr_params
  # @param [Array<String,Hash>] terms
  #
  # @return [Hash]
  #
  def add_to_fq!(solr_params, *terms)
    solr_params ||= {}
    solr_params[:fq] ||= []
    solr_params[:fq] +=
      terms.flat_map { |term|
        if term.is_a?(Hash)
          term.flat_map do |field, value|
            Array.wrap(value).map { |v| "#{field}:#{v}" }
          end
        else
          term.to_s
        end
      }.map { |term|
        term << ':' unless term.include?(':')
        term << '*' if term.end_with?(':')
        term
      }
    solr_params
  end

  # Remove matching terms from solr_params[:fq].
  #
  # @param [Hash]  solr_params        To be sent to Solr (via RSolr)
  # @param [Array] terms              One or more terms to add.
  #
  # @return [Hash]                    Resulting *solr_params*.
  #
  def remove_from_fq!(solr_params, *terms)
    solr_params ||= {}
    solr_params[:fq] ||= []
    unless solr_params[:fq].empty?
      patterns =
        terms.flat_map { |term|
          if term.is_a?(Hash)
            term.flat_map do |field, value|
              Array.wrap(value).map { |v| "#{field}:#{v unless v == '*'}" }
            end
          else
            term.to_s
          end
        }.map { |pattern|
          escape = ('\\' if pattern.start_with?('+'))
          anchor = ('$'  if pattern.include?(':') && !pattern.end_with?(':'))
          Regexp.new("^#{escape}#{pattern}#{anchor}")
        }
      solr_params[:fq].delete_if do |item|
        patterns.any? { |pattern| item =~ pattern }
      end
    end
    solr_params
  end

end

__loading_end(__FILE__)

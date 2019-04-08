# app/models/concerns/blacklight/lens/document/availability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils_service'
require 'ils_availability'

module Blacklight::Lens::Document

  # Blacklight::Lens::Document::Availability
  #
  module Availability

    # Availability statuses mapped on to natural language labels.
    #
    # @type [Hash{Symbol=>String}]
    #
    AVAILABILITY_NAMES = I18n.t('blacklight.availability.status').freeze

    # Availability statuses.
    #
    # @type [Array<Symbol>]
    #
    AVAILABILITY_STATUS = AVAILABILITY_NAMES.keys.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Availability information.
    #
    # @return [IlsAvailability]
    # @return [nil]
    #
    def availability
      @availability ||= fetch_availability
    end

    # Force a fetch of availability information.
    #
    # @return [IlsAvailability]
    # @return [nil]
    #
    def refresh_availability
      @availability = fetch_availability
    end

    # Get availability information from the source.
    #
    # @return [IlsAvailability]
    # @return [nil]
    #
    def fetch_availability
      return unless has_availability?
      index_availability || availability_service.get_availability(self)
    end

    # Indicate whether the document can have availability information.
    #
    def has_availability?
      id.start_with?('u') || has?(:availability_a)
    end

    # The availability status of the document.
    #
    # :none           The document does not have availability or the catalog
    #                 entry is "online-only".
    #
    # :unavailable    If there is a single library involved but it has no
    #                 available copies.
    #
    # :available      If there is a single library involved and it has at least
    #                 one available copy.
    #
    # :mixed          If there are multiple libraries with available copies.
    #
    # @return [Symbol]                A member of #AVAILABILITY_STATUS.
    #
    # @see IlsAvailability#library_available_counts
    #
    def availability_status
      if (av = availability).blank?
        :none
      elsif av.error?
        :error
      elsif (cp_counts = av.library_copy_counts).blank?
        :none
      elsif (av_counts = av.library_available_counts).blank?
        :unavailable
      elsif av_counts.find { |lib, available| available < cp_counts[lib] }
        :mixed
      else
        :available
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # availability_service
    #
    # @return [IlsService]
    #
    def availability_service
      @ils_service ||= IlsService.new
    end

    # index_availability
    #
    # @return [String]
    # @return [nil]
    #
    def index_availability
      data = first(:availability_a)
      IlsAvailability.new(data) if data.present?
    end

  end

end

__loading_end(__FILE__)

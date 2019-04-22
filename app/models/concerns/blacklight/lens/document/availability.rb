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

    # Empty availability data.
    #
    # @type [Hash]
    #
    AVAILABILITY_DATA_TEMPLATE = {
      status:    :none,
      locations: {}
    }.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Availability information.
    #
    # @param [Boolean] fetch          If *false*, do not acquire availability
    #                                   data if it is not already present.
    #
    # @return [IlsAvailability]
    # @return [nil]                   If #supports_availability? is *false*, or
    #                                   if *fetch* is *false* and data is not
    #                                   already present.
    #
    def availability(fetch = true)
      @availability ||= (fetch_availability if fetch)
    end

    # Force a fetch of availability information.
    #
    # @return [IlsAvailability]
    # @return [nil]                   If #supports_availability? is *false*.
    #
    def refresh_availability
      @availability = fetch_availability
    end

    # Get availability information from the source.
    #
    # @return [IlsAvailability]
    # @return [nil]                   If #supports_availability? is *false*.
    #
    # @see #index_availability
    # @see IlsService::Recv::Availability#get_availability
    #
    def fetch_availability
      return unless supports_availability?
      index_availability || availability_service.get_availability(self)
    end

    # Indicate whether the document can have availability information.
    #
    def supports_availability?
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
    # @param [Boolean] fetch          If *false*, do not acquire availability
    #                                   data if it is not already present.
    #
    # @return [Symbol]                A member of #AVAILABILITY_STATUS.
    #
    # @see IlsAvailability#library_copy_counts
    # @see IlsAvailability#library_available_counts
    #
    def availability_status(fetch = true)
      if (av = availability(fetch)).blank?
        :none
      elsif av.error?
        :error
      elsif (cp_counts = av.library_copy_counts).blank?
        :unavailable
      elsif (av_counts = av.library_available_counts).blank?
        :unavailable
      elsif av_counts.find { |lib, available| available < cp_counts[lib] }
        :mixed
      else
        :available
      end
    end

    # availability_data
    #
    # @param [Boolean] fetch          If *false*, do not acquire availability
    #                                   data if it is not already present.
    #
    # @return [Hash]
    #
    # @see #availability_status
    # @see IlsAvailability#library_copies_available
    # @see IlsAvailability#library_copies_unavailable
    #
    # == Example
    # {
    #   status: :available,
    #   locations: {
    #     '3rd Floor East Reading Room' => {
    #       id:     15,
    #       code:   '3EAST',
    #       name:   '3rd Floor East Reading Room',
    #       count:  1
    #     }
    #   }
    # }
    #
    def availability_data(fetch = true)
      AVAILABILITY_DATA_TEMPLATE.dup.tap do |result|
        if (av = availability(fetch)).present?
          result[:status] = availability_status
          library_copies =
            case result[:status]
              when :available, :mixed then av.library_copies_available
              when :unavailable       then av.library_copies_unavailable
            end
          result[:locations] =
            if library_copies.blank?
              av.lost
            else
              library_copies.map { |library, copies|
                count = {}
                copies.each do |copy|
                  location = copy.location.name.to_sym
                  count[location] ||= copy.location.to_hash.merge(count: 0)
                  count[location][:count] += 1
                end
                [library, count]
              }.to_h
            end
        end
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

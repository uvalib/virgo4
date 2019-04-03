# app/services/ils_service/recv/location_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::LocationList

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the list of locations from Sirsi.
    #
    # @param [Hash, nil] opt
    #
    # @return [IlsLocationList]
    #
    def get_location_list(**opt)
      get_data('list', 'locations', opt)
      data = response&.body&.presence
      #data = location_list_json_test_data # TODO: testing - remove
      #data = location_list_xml_test_data  # TODO: testing - remove
      IlsLocationList.new(data, error: @exception)
    end

    # =========================================================================
    # :section: TODO: testing - remove
    # =========================================================================

    private

    def location_list_json_test_data
      {
        locations: [
          {
            id:   '123',
            code: 'LOC-ONE',
            name: 'The First Location',
          },
          {
            id:   '234',
            code: 'LOC-TWO',
            name: 'The Second Location'
          },
        ]
      }
    end

    def location_list_xml_test_data
      <<~HEREDOC
        <locations>
          <location id="123" code="LOC-ONE">
            <name>The First Location</name>
          </location>
          <location id="234" code="LOC-TWO">
            <name>The Second Location</name>
          </location>
        </locations>
      HEREDOC
    end

  end

end

__loading_end(__FILE__)

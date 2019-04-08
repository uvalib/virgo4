# app/services/ils_service/recv/library_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::LibraryList

    include Recv

    # Get the list of libraries from Sirsi.
    #
    # @param [Hash, nil] opt
    #
    # @return [IlsLibraryList]
    #
    def get_library_list(**opt)
      get_data('list', 'libraries', opt)
      data = response&.body&.presence
      #data = library_list_json_test_data # TODO: testing - remove
      #data = library_list_xml_test_data  # TODO: testing - remove
      IlsLibraryList.new(data, error: @exception)
    end

    # =========================================================================
    # :section: TODO: testing - remove
    # =========================================================================

    private

    def library_list_json_test_data
      {
        libraries: [
          {
            id:          '123',
            code:        'ALDERMAN',
            name:        'Alderman',
            deliverable: true,
            holdable:    true,
            remote:      false,
          },
          {
            id:          '321',
            code:        'NAMREDLA',
            name:        'Namredla',
            deliverable: false,
            holdable:    true,
            remote:      true,
          },
        ]
      }
    end

    def library_list_xml_test_data
      <<~HEREDOC
        <libraries>
          <library id="123" code="ALDERMAN">
            <name>Alderman</name>
            <deliverable>true</deliverable>
            <holdable>true</holdable>
            <remote>false</remote>
          </library>
          <library id="321" code="NAMREDLA">
            <name>Namredla</name>
            <deliverable>false</deliverable>
            <holdable>true</holdable>
            <remote>true</remote>
          </library>
        </libraries>
      HEREDOC
    end

  end

end

__loading_end(__FILE__)

# app/services/ils_service/recv/availability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::Availability

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # get_availability
    #
    # @param [SolrDocument] doc
    # @param [Hash, nil]    opt
    #
    # @return [IlsAvailability]
    #
    def get_availability(doc, **opt)
      return unless doc.is_a?(SolrDocument) && (ckey = to_ckey(doc.id))
      get_data('items', ckey, opt)
      data = response&.body&.presence
      #data = availability_json_test_data # TODO: testing - remove
      #data = availability_xml_test_data  # TODO: testing - remove
      IlsAvailability.new(data, doc: doc, error: @exception)
    end

    # =========================================================================
    # :section: TODO: testing - remove
    # =========================================================================

    private

    TEST_DOC_ID = 'u7875793'

    def availability_json_test_data(doc_id = TEST_DOC_ID)

      library = {
        id:          2,
        code:        'ALDERMAN',
        name:        'Alderman',
        deliverable: true,
        holdable:    true,
      }

      home_location = {
        id:   '138',
        code: 'STACKS',
        name: 'Stacks'
      }

      checked_out = {
        id:   '2',
        code: 'CHECKEDOUT',
        name: 'CHECKED OUT'
      }

      item_type = {
        id:   '999',
        code: 'book'
      }

      # Returned data:
      {
        catalogItem: {
          key:     to_ckey(doc_id),
          status:  0,
          canHold: {
            value:   'yes',
            message: 'Yes this catalog item can be held.'
          },
          holdings: [
            {
              callSequence: 1,
              callNumber:   'PJ7517 .C58 2018',
              holdable:     true,
              shadowed:     false,
              shelvingKey:  'PJ 007517 .C58  2018',
              library:      library,
              copies: [
                {
                  copyNumber:        1,
                  barCode:           'X032567675',
                  shadowed:          false,
                  currentPeriodical: false,
                  lastCheckout:      '2019-03-01T10:45:06-05:00',
                  circulate:         'Y',
                  currentLocation:   home_location,
                  homeLocation:      home_location,
                  itemType:          item_type
                },
                {
                  copyNumber:        2,
                  barCode:           'X032567676',
                  shadowed:          false,
                  currentPeriodical: false,
                  lastCheckout:      '2019-03-01T10:45:06-05:00',
                  circulate:         'M',
                  currentLocation:   checked_out,
                  homeLocation:      home_location,
                  itemType:          item_type
                },
              ]
            },
          ]
        }
      }.tap do |result|
        is_available = ((rand * 100).round % 2).zero?
        entry   = result[:catalogItem]
        holding = entry[:holdings][0]
        copy    = holding[:copies][0]
        if is_available
          entry[:canHold][:value] = 'no'
          holding[:holdable]      = false
          copy[:circulate]        = 'Y'
          copy[:currentLocation]  = home_location
        else
          entry[:canHold][:value] = 'yes'
          holding[:holdable]      = true
          copy[:circulate]        = 'M'
          copy[:currentLocation]  = checked_out
        end
      end
    end

    def availability_xml_test_data(doc_id = TEST_DOC_ID)

      library = <<~HEREDOC
        <library id="2" code="ALDERMAN">
          <name>Alderman</name>
          <deliverable>true</deliverable>
          <holdable>true</holdable>
        </library>
      HEREDOC

      home_location = %Q(id="138" code="STACKS"><name>Stacks</name)
      checked_out   = %Q(id="2" code="CHECKEDOUT"><name>CHECKED OUT</name)
      item_type     = %Q(<itemType id="999" code="book"/>)

      # Returned data:
      <<~HEREDOC
        <catalogItem key="#{to_ckey(doc_id)}">
          <status>0</status>
          <canHold value="yes">
            <message>Yes this catalog item can be held.</message>
          </canHold>
  
            <holding callSequence="1" callNumber="PJ7517 .C58 2018" holdable="true" shadowed="false">
              <shelvingKey>PJ 007517 .C58  2018</shelvingKey>
              "#{library}"
  
                <copy copyNumber="1" barCode="X032567675" shadowed="false" currentPeriodical="false">
                  <lastCheckout>2019-03-01T10:45:06-05:00</lastCheckout>
                  <circulate>M</circulate>
                  <currentLocation "#{checked_out}"></currentLocation>
                  <homeLocation "#{home_location}"></homeLocation>
                  "#{item_type}"
                </copy>
                <copy copyNumber="2" barCode="X032567676" shadowed="false" currentPeriodical="false">
                  <lastCheckout>2019-03-01T10:45:06-05:00</lastCheckout>
                  <circulate>Y</circulate>
                  <currentLocation "#{home_location}"></currentLocation>
                  <homeLocation "#{home_location}"></homeLocation>
                  "#{item_type}"
                </copy>
  
            </holding>
  
        </catalogItem>
      HEREDOC
    end

  end

end

__loading_end(__FILE__)

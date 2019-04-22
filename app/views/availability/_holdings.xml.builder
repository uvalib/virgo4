# app/views/availability/_holdings.xml.builder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render holdings for a single document in XML.

doc = document ||= @document
options ||= { format: :xml }
xml_opt ||= { builder: xml, skip_instruct: true, root: 'holding' }

error = holdings = missing = nil

unique_site = unique_site_type(doc) # :kluge, et. al.
if !unique_site && (availability = doc&.availability)
  error    = availability.error_message
  holdings = availability.holdings if availability.visible_copies.nonzero?
  missing  = availability.lost     if holdings.blank?
end

xml.holdings do

  if unique_site

    xml.holding unique_site_row(doc, options)

  elsif error

    xml.holding error_row(options.merge(error: error))

  elsif holdings

    holdings.each do |holding|
      holding.copies.each do |copy|
        item_row(doc, holding, copy, options).to_xml(xml_opt)
      end
    end

  elsif missing

    missing.each_pair do |lib, note|
      missing_row(doc, lib, note, options).to_xml(xml_opt)
    end

  else

    xml.holding no_info_row(options)

  end

end

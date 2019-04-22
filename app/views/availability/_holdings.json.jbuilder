# app/views/availability/_holdings.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# Render holdings for a single document in JSON.

doc = document ||= @document
options ||= { format: :json }

error = holdings = missing = nil

unique_site = unique_site_type(doc) # :kluge, et. al.
if !unique_site && (availability = doc&.availability)
  error    = availability.error_message
  holdings = availability.holdings if availability.visible_copies.nonzero?
  missing  = availability.lost     if holdings.blank?
end

json.holdings do

  if unique_site

    json.child! { json.merge! unique_site_row(doc, options) }

  elsif error

    json.child! { json.merge! error_row(options.merge(error: error)) }

  elsif holdings

    holdings.each do |holding|
      holding.copies.each do |copy|
        json.child! { json.merge! item_row(doc, holding, copy, options) }
      end
    end

  elsif missing

    missing.each_pair do |lib, note|
      json.child! { json.merge! missing_row(doc, lib, note, options) }
    end

  else

    json.child! { json.merge! no_info_row(options) }

  end

end

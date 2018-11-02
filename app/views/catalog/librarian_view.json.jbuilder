# app/views/catalog/librarian_view.json.jbuilder
#
# frozen_string_literal: true
# warn_indent:           true
#
# == Implementation Notes
# To facilitate viewing in a browser, MARC tags are preceded by a space to
# prevent the JSON viewers in both Chrome and Firefox from mis-sorting the
# results.

json.id  @document.id
json.url full_url_for(url_for_document(@document, format: 'json'))
json.marc do
  marc_fields = @document.to_marc
  json.set!('LEADER', marc_fields.leader)
  marc_fields.each do |field|
    tag = " #{field.tag}" # NOTE: Tag name prefixed with a space (see above).
    if field.is_a?(MARC::ControlField)
      json.set!(tag, field.value)
    else
      json.set!(tag) do
        json.ind1 field.indicator1.to_s
        json.ind2 field.indicator2.to_s
        json.subfields do
          field.each do |subfield|
            json.set!(subfield.code, subfield.value)
          end
        end
      end
    end
  end
end

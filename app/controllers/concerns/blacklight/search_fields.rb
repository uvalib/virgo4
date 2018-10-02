# NOTE: This is a temporary replacement for the Blacklight file

module Blacklight::SearchFields

  # Looks up search field config list from blacklight_config[:search_fields], and
  # 'normalizes' all field config hashes using normalize_config method.
  def search_field_list
    blacklight_config.search_fields.values
  end

  # Returns default search field, used for simpler display in history, etc.
  # if not set in blacklight_config, defaults to first field listed in #search_field_list
  def default_search_field
    blacklight_config.default_search_field || search_field_list.first
  end

  # NOTE: Added for blacklight_advanced_search
  def search_field_def_for_key(key)
    blacklight_config.search_fields[key]
  end

end

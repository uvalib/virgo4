# lib/ext/ebsco-eds/lib/ebsco/eds/info.rb
#
# Inject EBSCO::EDS::Info extensions and replacement methods.

__loading_begin(__FILE__)

# Override EBSCO::EDS definitions.
#
# @see EBSCO::EDS::Info
#
module EBSCO::EDS::InfoExt

  # ===========================================================================
  # :section: EBSCO::EDS::Info overrides
  # ===========================================================================

  public

  # Override initializer to handle facet pagination.
  #
  # @param [Hash]      info           Raw return from API message.
  # @param [Hash, nil] config
  #
  # This method overrides:
  # @see EBSCO::EDS::RetrievalCriteria#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  def initialize(info, config = {})
    super
    @raw = info.with_indifferent_access
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  public

  # Return raw information from the EDS API message.
  #
  # @return [Hash]
  #
  def raw
    @raw
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override EBSCO::EDS::Info => EBSCO::EDS::InfoExt

__loading_end(__FILE__)

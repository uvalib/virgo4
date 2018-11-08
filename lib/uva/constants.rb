# lib/uva/constants.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module UVA

  # Various useful constants.
  #
  module Constants

    # Subnet for production systems.
    PRODUCTION_SUBNET = 'lib.virginia.edu'

    # String to cause text to continue on the next line within an HTML element.
    HTML_NEW_LINE = '<br/>'.html_safe.freeze

  end

  module VCard
    ORGANIZATION  = 'University of Virginia Library'
    ADDRESS       = 'PO Box 400113, Charlottesville, VA 22904-4113'
    TELEPHONE     = '434-924-3021'
    FAX           = '434-924-1431'
    EMAIL         = 'library@virginia.edu'
  end

  # External URLs.
  #
  module URL

    UVA_HOST                  = 'www.virginia.edu'
    UVA_ROOT                  = "http://#{UVA_HOST}"
    UVA_HOME                  = UVA_ROOT
    COPYRIGHT                 = "#{UVA_ROOT}/siteinfo/copyright"

    ITS_HOST                  = 'its.virginia.edu'
    ITS_ROOT                  = "http://#{ITS_HOST}"
    ITS_HOME                  = ITS_ROOT
    NETBADGE_INFO             = "#{ITS_ROOT}/netbadge/"

    NETBADGE_HOST             = 'netbadge.virginia.edu'
    NETBADGE_ROOT             = "https://#{NETBADGE_HOST}"
    NETBADGE_LOGIN            = NETBADGE_ROOT
    NETBADGE_LOGOUT           = "#{NETBADGE_ROOT}/logout.cgi"

    UVA_PROXY_HOST            = 'proxy01.its.virginia.edu'
    UVA_PROXY_ROOT            = "https://#{UVA_PROXY_HOST}"
    UVA_PROXY_PREFIX          = "#{UVA_PROXY_ROOT}/login?url="

    IR_HOST                   = 'libra.virginia.edu'
    IR_ROOT                   = "https://#{IR_HOST}"
    LIBRA_HOME                = IR_ROOT
    LIBRA                     = IR_ROOT

    GIS_HOST                  = 'gis.lib.virginia.edu'
    GIS_ROOT                  = "https://#{GIS_HOST}"
    GIS_HOME                  = GIS_ROOT
    GIS                       = GIS_ROOT

    XTF_HOST                  = 'xtf.lib.virginia.edu'
    XTF_ROOT                  = "http://#{XTF_HOST}"
    XTF                       = "#{XTF_ROOT}/xtf"
    XTF_SEARCH                = "#{XTF}/search"
    XTF_ADVANCED_SEARCH       = "#{XTF_SEARCH}?smode=advanced"
    XTF_AUTHOR_BROWSE         = "#{XTF_SEARCH}?browse-creator=first;sort=creator"
    XTF_TITLE_BROWSE          = "#{XTF_SEARCH}?browse-title=first;sort=title"
    XTF_FACET_BROWSE          = "#{XTF_SEARCH}?browse-all=yes"

    LIBGUIDES_HOST            = 'guides.lib.virginia.edu'
    LIBGUIDES_ROOT            = "https://#{LIBGUIDES_HOST}"
    LIBGUIDES_HOME            = LIBGUIDES_ROOT
    LIBGUIDES                 = LIBGUIDES_ROOT
    DATABASES                 = "#{LIBGUIDES}/az.php"
    FINDING_GOV_INFO          = "#{LIBGUIDES}/findinggovinfo"
    ILL_REQUESTS              = "#{LIBGUIDES}/requests"
    JOURNAL_FINDER            = "#{LIBGUIDES}/journalfinder"
    MUSIC_GUIDE               = "#{LIBGUIDES}/music"

    LIBRARY_HOST              = 'library.virginia.edu'
    LIBRARY_ROOT              = "https://#{LIBRARY_HOST}"
    LIBRARY_HOME              = LIBRARY_ROOT
    LIBRARY                   = LIBRARY_ROOT
    HOURS                     = "#{LIBRARY}/hours"
    ASK_A_LIBRARIAN           = "#{LIBRARY}/askalibrarian"
    SERVICES                  = "#{LIBRARY}/services"
    LEO                       = "#{LIBRARY}/services/ils/leo"
    PURCHASE_REQUESTS         = "#{LIBRARY}/services/purchase-requests"
    ACCESSIBILITY             = "#{LIBRARY}/services/accessibility-services"
    COURSE_RESERVES           = "#{LIBRARY}/services/course-reserves"
    COURSE_RESERVES_PERSONAL  = "#{LIBRARY}/services/course-reserves/personal"
    DIGITIZATION              = "#{LIBRARY}/digitization/#speccol-mats"
    POLICIES                  = "#{LIBRARY}/policies"
    CIRCULATION_POLICY        = "#{LIBRARY}/policies/circulation"
    SITE_SEARCH               = "#{LIBRARY}/site-search"
    MAP                       = "#{LIBRARY}/map"
    PRESS                     = "#{LIBRARY}/press"
    JOBS                      = "#{LIBRARY}/jobs"
    STAFF_DIRECTORY           = "#{LIBRARY}/staff"
    RESEARCH                  = "#{LIBRARY}/research"
    COLLECTIONS               = "#{LIBRARY}/collections"
    ABOUT_PDA                 = "#{LIBRARY}/about-available-to-order-items"

    SC_LIBRARY_HOST           = 'small.library.virginia.edu'
    SC_LIBRARY_ROOT           = "https://#{SC_LIBRARY_HOST}"
    SC_LIBRARY_HOME           = SC_LIBRARY_ROOT
    SC_LIBRARY                = SC_LIBRARY_ROOT

    PIWIK_HOST                = 'analytics.lib.virginia.edu'
    PIWIK_ROOT                = "https://#{PIWIK_HOST}"
    PIWIK                     = "#{PIWIK_ROOT}/index.php"
    PIWIK_OPT_OUT             = "#{PIWIK}?module=CoreAdminHome&action=optOut&language=en"

    SIRSI_HOST                = 'ils.lib.virginia.edu'
    SIRSI_ROOT                = "https://#{SIRSI_HOST}"
    SIRSI                     = SIRSI_ROOT
    SIRSI_HOME                = SIRSI_ROOT
    SIRSI_BASE                = "#{SIRSI}/uhtbin/cgisirsi/x/UVA-LIB"
    SIRSI_COURSE_RESERVES     = "#{SIRSI_BASE}/X/36/1252/X"

    FEDORA_PROXY_HOST         = 'fedoraproxy.lib.virginia.edu'
    FEDORA_PROXY_ROOT         = "http://#{FEDORA_PROXY_HOST}"
    FEDORA_PROXY              = FEDORA_PROXY_ROOT

    EBSCO_EDS_HOST            = 'eds-api.ebscohost.com'

  end

end

__loading_end(__FILE__)

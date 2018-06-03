# Virgo 4.x - based on Blacklight 6

This project is proof-of-concept for a "greenfield" follow-on to the current
Virgo search-and-discovery interface for the University of Virginia Library
system.

## Installation

The application is based on the latest versions of Ruby, Rails and Blacklight.

### Versions

To execute, the following software should be in place before installation.

_(Note that some adjustments were required due to Ruby 2.5.)_

##### Development and execution environment

|            | VERSION       | NOTES
|------------|---------------|-------------------------------------------------
| ruby       | \>= 2.5.1     |
| bundler    | \>= 1.16      | Must be [explicitly installed for ruby 2.5][1].
| rubygems   | \>= 2.7.6     | Prior versions have a [problem with ruby 2.5][2].
| java       | \>= 1.8.0_161 | Per Blacklight [QuickStart] documentation.
| rvm        | \>= 1.29.3    | (Used at UVA; not required for general use.)
| Solr       | \>= 4         | (Configured for external UVA Solr server.)

##### Selected notes for [Gemfile] gem versions

|                            | VERSION  | NOTES
|----------------------------|----------|--------------------------------------
| rails                      | \>= 5.2  |
| blacklight                 | \>= 6.15 | Display templates and interface to [Solr].
| blacklight-marc            | \>= 6.2  | Processing of [MARC] metadata.
| blacklight_advanced_search | \>= 6.3  | Advanced field and facet searching.
| devise                     | \>= 4.4  | Prior versions have a [problem with ruby 2.5][3].
| ebsco-eds                  | \>= 1.0  | Translates Solr queries in [EBSCO EDS] searches.

### Steps

* Verify execution environment:

  * `ruby --version` \>= 2.5.1
  * `bundle --version` \>= 1.16.0
  * `gem --version` \>= 2.7.6

* Set up the code repository:

  ```shell
  git clone https://github.com/uvalib/virgo4
  cd virgo4
  bundle install
  ```

* Localize URLs to match your deployment environment:

  * Edit [config/environments/production.rb][env_prod] for e-mail settings.
  * Edit [config/blacklight.yml][solr_yml] for Solr instance URL/port.
  * Edit [config/database.yml][db_yml] for database type/URL/port.

* Create empty database tables:

  ```shell
  rake db:migrate
  ```

* Localize metadata fields to match your Solr configuration:

  * Edit [app/controllers/concerns/config/_solr.rb][config_solr] to provide the
    literal Solr field names for:
    - Facets
    - Index (search results) display fields
    - Show (item details) display fields
    - Search fields
    - Sort fields
    
  * Edit [config/locales/zz_local.en.yml][i18n_fields] to associate base field
    names with human-readable field labels.
    >
    | YAML SUBTREE                  | USAGE
    |:------------------------------|:-----------------------------------------
    | blacklight.field              | General field labels.
    | blacklight.facet_field        | Labels for fields used as facets.
    | blacklight.index_field        | Labels for fields in search results.
    | blacklight.show_field         | Labels for fields on item details pages.
    | blacklight.search_field       | Labels for the "search field" menu.
    | blacklight.sort_field         | Labels for the "sort by" menu.
    | blacklight.lens               | Labels used in any search lens.
    | blacklight.*LLL*.field        | Labels for fields only on the *LLL* lens.
    | blacklight.*LLL*.facet_field  | Labels for facets only on the *LLL* lens.
    | *etc*                         |

  * Edit other [config/locales/*.yml](config/locales) files to customize the
    display of other human-readable elements.
    
* Sensitive information is not stored with the code but supplied through the
  environment when executing the application:

  ```shell
  export SECRET_KEY_BASE='xxx' # Generate once with `rails secret` and save.
  export EDS_PROFILE='xxx'     # Supplied to you from EBSCO.
  export EDS_CACHE_DIR='/tmp/faraday_cache/eds' # vs. /tmp/faraday_cache/solr
  export TRACE_LOADING='false'        # Optional; already *false* by default.
  export TRACE_CONCERNS='false'       # Optional; already *false* by default.
  export TRACE_NOTIFICATIONS='false'  # Optional; already *false* by default.
  rails server
  ```

## Background

More to come...

<!---------------------------------------------------------------------------->
<!-- Notes:
<!---------------------------------------------------------------------------->
[1]: https://github.com/ruby/ruby/commit/7825e8363d4b2ccad8e2d3f5eeba9e26f6656911
[2]: https://stackoverflow.com/questions/19061774/cannot-load-such-file-bundler-setup-loaderror
[3]: https://github.com/plataformatec/devise/issues/4736

<!---------------------------------------------------------------------------->
<!-- File and directory references:
REF ---------- LINK ---------------------------- TOOLTIP --------------------->
[Gemfile]:     Gemfile
[env_prod]:    config/environments/production.rb
[env_dev]:     config/environments/development.rb
[env_test]:    config/environments/test.rb
[solr_yml]:    config/blacklight.yml
[db_yml]:      config/database.yml
[config_solr]: app/controllers/concerns/config/_solr.rb
[i18n_fields]: config/locales/zz_local.en.yml

<!---------------------------------------------------------------------------->
<!-- Other link references:
REF ---------- LINK ---------------------------- TOOLTIP --------------------->
[version_url]: https://github.com/uvalib/virgo4
[Quickstart]:  https://github.com/projectblacklight/blacklight/wiki/Quickstart
[Solr]:        http://lucene.apache.org/solr/
[MARC]:        https://www.loc.gov/marc/
[EBSCO EDS]:   https://www.ebscohost.com/discovery/api

<!-- vi: set filetype=markdown: set wrap: -->

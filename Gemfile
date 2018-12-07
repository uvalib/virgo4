# Gemfile

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

# =============================================================================
# :section: Rails
# =============================================================================

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster.
# Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i(mingw mswin x64_mingw jruby)

# =============================================================================
# :section: Testing and development
# =============================================================================

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console.
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Code coverage
  gem 'simplecov', require: false
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # Use Capistrano for deployment
  # gem 'capistrano-rails'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

# =============================================================================
# :section: Blacklight with ebsco-eds
#
# Via `rails generate blacklight:install --devise --marc --solr_version=latest`
#
# @see https://github.com/projectblacklight/blacklight/wiki/Quickstart
# @see https://github.com/projectblacklight/blacklight_advanced_search
# @see https://github.com/projectblacklight/blacklight/blob/release-4.7/doc/Blacklight-4.0-release-notes-and-upgrade-guide.md
# @see https://github.com/ebsco/edsapi-ruby/wiki/Quick-Start
# =============================================================================

# Blacklight and supporting gems.
gem 'blacklight', '< 8', github: 'RayLubinsky/blacklight'
gem 'rsolr', '>= 1.0', '< 3'
gem 'bootstrap', '~> 4.0'
gem 'jquery-rails'
gem 'popper_js'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'devise'
gem 'devise-guests', '~> 0.6'

# Blacklight Marc gem.
gem 'blacklight-marc', '~> 6.1' # TODO: '7.0.0.rc1'

# Blacklight Advanced Search gem.
#gem 'blacklight_advanced_search', '>= 6.4'
gem 'blacklight_advanced_search', '~> 6.4', github: 'RayLubinsky/blacklight_advanced_search'

# Blacklight::Gallery
gem 'blacklight-gallery', '~> 0.11'

# EBSCO EDS gem for articles search.
gem 'ebsco-eds', '1.0.0' # TODO: '~> 1.0'

# =============================================================================
# :section: Local
# =============================================================================

gem 'curb'

# =============================================================================
# :section: Blacklight testing and development
# =============================================================================

group :development, :test do
  # Only useful if running a local Solr instance.
  gem 'solr_wrapper', '>= 0.3', require: false
end

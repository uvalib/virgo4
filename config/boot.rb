# config/boot.rb

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
#require 'bootsnap/setup' # Speed up boot time by caching expensive operations.

# Work-around for bootsnap v1.3.0 making breakpoints inoperable.
begin
  require 'bootsnap'
  in_debugger = defined?(Debase) && Debase.started?
  cache_dir   = ENV.fetch('BOOTSNAP_CACHE_DIR', 'tmp/cache')
  development = (ENV.fetch('RAILS_ENV', 'development') == 'development')
  Bootsnap.setup(
    cache_dir:            cache_dir,
    development_mode:     development,
    load_path_cache:      true,
    autoload_paths_cache: true,
    disable_trace:        in_debugger,
    compile_cache_iseq:   !in_debugger,
    compile_cache_yaml:   true
  )
end

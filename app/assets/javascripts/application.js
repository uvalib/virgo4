// This is a manifest file that'll be compiled into application.js, which will
// include all the files listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or
// any plugin's vendor/assets/javascripts directory can be referenced here
// using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at
// the bottom of the compiled file. JavaScript code in this file should be
// added after the last require_* statement.
//
// See Sprockets README https://github.com/rails/sprockets#sprockets-directives
// for details about supported directives.
//
//= require rails-ujs
//= require activestorage
//= require turbolinks
//
//  Required by Blacklight
//
//= require jquery
//= require bootstrap
//
//  Blacklight
//
//  The standard 'require blacklight/blacklight' cannot be used because it does
//  not allow the code to be overridden properly.  For the sake of the modified
//  autocomplete.js, all of the other Blacklight JavaScript source files had to
//  be copied locally (which are loaded with the 'Local sources' below).
//  Note that blacklight/core must be loaded first to define Blacklight.
//
//= require blacklight/core
//= require blacklight_advanced_search
//
//  Local sources
//
//= require_tree .

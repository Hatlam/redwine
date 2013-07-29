require 'rubygems'
require 'bundler'
Bundler.setup

require 'middleman'
require 'middleman-core/preview_server'

module Middleman::PreviewServer
  def self.preview_in_rack
    @options = {}
    @app = new_app
    start_file_watcher
  end
end

# require "rack/contrib/try_static"
# use Rack::TryStatic, :root => "srcsrc", :urls => %w[/], :try => ['.html','.json']


# require 'rack/offline'
# offline = Rack::Offline.configure do
#   # cache "index.html"
#   
#   cache "javascripts/vendor/jquery.js"
#   cache "javascripts/vendor/handlebars.js"
#   cache "javascripts/vendor/ember.js"
#   cache "javascripts/vendor/ember-data.js"
# 
#   network "*"
# end
#  
# map("/offline.manifest") { run offline }

Middleman::PreviewServer.preview_in_rack
run Middleman::PreviewServer.app.class.to_rack_app

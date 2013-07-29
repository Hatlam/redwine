require 'hamlbars'

page "/index.html", :layout => false

###
# Helpers
###


# helpers do
  # def stylesheet_include_tag(name)
  #   "<link rel=\"stylesheet\" href=\"#{self.css_dir}/#{name}.css\">"
  # end
# end

# set :source, 'ui_source'
# set :build_dir, 'ui'

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
# 
set :haml, { :attr_wrapper => "\"" }
set :debug_assets, true

# Build-specific configuration
configure :build do
  activate :relative_assets
  set :debug_assets, false
  # ignore 'javascripts/*/*'
  ignore 'stylesheets/normalize.*'
  ignore 'stylesheets/main.*'
  ignore 'stylesheets/*/*'
  ignore 'layouts/*'
end

activate :deploy do |deploy|
  deploy.method = :rsync
  deploy.user = "igor"
  deploy.host = "karies.cursor.ru"
  deploy.path = "/www/phpprojects/redwine"
end

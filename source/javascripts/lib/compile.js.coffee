window.compile = (templateUrl) ->
  templateName = templateUrl.split('/').reverse()[0].replace('.handlebars', '')
  $.ajax
    url: templateUrl
    cache: false
    async: false
    success: (source) ->
      input = Ember.Handlebars.precompile source.toString()
      Ember.TEMPLATES[templateName] = Ember.Handlebars.template(input)


#= require lib/dragndrop


Mode = Em.Object.extend
  selected: 'my'
  isMy: Em.computed.equal('selected', 'my')
  isAll: Em.computed.equal('selected', 'all')

  list: [
    Em.Object.create { id: 'my', title: 'Мои задачи' }
    Em.Object.create { id: 'all', title: 'Все задачи' }
  ]


AjaxIndicator = Em.Object.extend
  init: ->
    d = $ document
    d.ajaxStart => @set 'now', true
    d.ajaxStop =>
      t = @get('last')
      clearTimeout(t) if t
      @set 'last', setTimeout =>
        @set 'now', false
      , 1000

  last: null
  now: false


 
# application
window.App =  Em.Application.create
  REDMINE_URL: 'http://redmine.cursor.ru'
  # LOG_TRANSITIONS: true
  debug: true
  mode: Mode.create()
  ajax: AjaxIndicator.create()

App.deferReadiness()



window.Auth = Em.Object.extend
  apiKey: null

  init: ->
    @set 'ready', Em.RSVP.Promise (resolve) =>
      @addObserver 'apiKey', =>
        key = @get 'apiKey'
        if key
          $.cookie 'api_key', key
          unless App.user
            Em.run.next ->
              q = App.User.find(current: true)
              q.one 'didLoad', ->
                App.user = q.get('firstObject')
                resolve()

    @set 'apiKey', $.cookie 'api_key'



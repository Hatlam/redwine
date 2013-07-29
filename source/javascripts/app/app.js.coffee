#= require bootstrap-dropdown
#= require lib/dragndrop

# auth
Auth = Em.Object.extend
  apiKey: null

  init: ->
    @set 'ready', Em.RSVP.Promise (resolve) =>
      @addObserver 'apiKey', =>
        key = @get 'apiKey'
        if key
          $.cookie 'api_key', key
          unless App.user
            Em.run.next ->
              App.user = App.User.find('current')
              App.User.loadedSome().then ->
                resolve()


    @set 'apiKey', $.cookie 'api_key'



Mode = Em.Object.extend
  selected: 'my'
  list: [
    Em.Object.create { id: 'my', title: 'Мои задачи' }
    Em.Object.create { id: 'all', title: 'Все задачи' }
  ]

  isAll: (-> @get('selected') is 'all' ).property('selected')


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
  # LOG_TRANSITIONS: true
  debug: true
  REDMINE_URL: 'http://redmine.cursor.ru/'
  mode: Mode.create()
  ajax: AjaxIndicator.create()

App.deferReadiness()









# routes
App.Router.map ->
  @resource 'projects', ->
    @resource 'project', path: ':project_id'

Em.Route.reopen
  redirect: ->
    unless App.auth.get 'apiKey'
      @transitionTo 'index'

App.ApplicationRoute = Em.Route.extend
  redirect: ->
    if App.auth.get 'apiKey'
      @transitionTo 'projects'
    else
      @transitionTo 'index'


App.ProjectsRoute = Em.Route.extend
  model: ->
    App.Project.find()

  
  setupController: (controller, model) ->
    @_super controller, model
     
    App.User.find()
  
    @controllerFor('laterIssues').set 'content', App.Issue.all()
    @controllerFor('nowIssues').set 'content', App.Issue.all()
    @controllerFor('nextIssues').set 'content', App.Issue.all()
    @controllerFor('memberships').set 'content', App.Membership.all()


App.ProjectRoute = Em.Route.extend
  setupController: (controller, model) ->
    @_super controller, model
    
    @controllerFor('laterIssues').set 'project', model
    @controllerFor('nowIssues').set 'project', model
    @controllerFor('nextIssues').set 'project', model
    @controllerFor('memberships').set 'project', model

    App.auth.ready.then =>

      App.Membership.find(project_id: model.id)

      openedIssues = App.Issue.find
        project_id: model.id
        status_id: 'opened'
      
      doneIssues = App.Issue.find
        project_id: model.id
        # assigned_to_id: App.user.get('serverId')
        # limit: 15
        status_id: 'closed'

      @controllerFor('doneIssues').set 'content', doneIssues
 
  request: ->
    




# models

# Serializer = DS.RESTSerializer.extend
#   serializeId: (id) ->
#     console.log 'dsds', id
#     @_super id
get = Em.get

Serializer = DS.RESTSerializer.extend
  

  # keyForBelongsTo: (type, name) ->
  #   key = this.keyForAttributeName(type, name)

  #   if @embeddedType(type, name) is 'always'
  #     return key

  #   key + "_id"
  
  serializeId: (id, child) ->
    if child
      serverId = child.get('serverId')
      id = serverId if serverId isnt null
    @_super(id)
    

  extractBelongsTo: (type, hash, key) ->
    id = hash[key] || hash[key.replace(/_id$/,'')]
    if typeof id is 'object'
      id = id.id
    # console.log 'dfdf', hash, key, id
    id
  
  # addBelongsTo: (hash, record, key, relationship) ->
  #   type = record.constructor
  #   name = relationship.key
  #   value = null
  #   includeType = (relationship.options && relationship.options.polymorphic)


  #   if @embeddedType(type, name) is 'always'
  #     if embeddedChild = get(record, name)
  #       value = @serialize(embeddedChild, { includeId: true, includeType: includeType })
  #     
  #     hash[key] = value
  #   else
  #     child = get(record, relationship.key)
  #     id = get(child, 'id')

  #     if relationship.options && relationship.options.polymorphic && !Ember.isNone(id)
  #       @addBelongsToPolymorphic(hash, key, id, child.constructor)
  #     else
  #       hash[key + '_id'] = @serializeId(id, child)
         
    
 



Adapter = DS.RESTAdapter.extend Em.Evented,
  serializer: Serializer

  # find: (store, type, id) ->
  #   root = @rootForType type
  #   adapter = @

  #   @ajax(@buildURL(root, id), "GET")
  #     .then((json) ->
  #       loadedId = json[root].id || id
  #       
  #       adapter.didFindRecord(store, type, json, id)
  #     ).then(null, DS.rejectionHandler)
  
  findQuery: (store, type, query, recordArray) ->
    root = this.rootForType(type)
    adapter = this

    url = @buildURL root
    if type?.url
      url = type.url url, query

    @ajax(url, "GET",
      data: query
    ).then((json) ->
      adapter.didFindQuery(store, type, json, recordArray)
    ).then(null, DS.rejectionHandler)


  # serlializer:  Serializer
  ajax: (url, type, hash) ->
    adapter = @
      
    new Ember.RSVP.Promise (resolve, reject) ->
      hash = hash || {}
      hash.url = url + '.json'

      hash.type = type
      hash.dataType = 'json'
      hash.context = adapter
      hash.headers =
        'X-Redmine-API-Key': App.auth.get 'apiKey'
      hash.crossDomain = true


      if hash.data and type isnt 'GET'
        hash.contentType = 'application/json; charset=utf-8'
        hash.data = JSON.stringify(hash.data)
      

      hash.success = (json) ->
        # parse response
        delete json.limit
        delete json.total_count
        delete json.offset
    
        if json.user
          json.user.server_id = json.user.id
       
        Ember.run(null, resolve, json)


      hash.error = (jqXHR, textStatus, errorThrown) ->
        Ember.run(null, reject, jqXHR)
        Ember.run.next ->
          adapter.trigger 'error', errorThrown
      
      Ember.$.ajax(hash)


Adapter.configure "plurals",
  'issue_status': 'issue_statuses'

DS.Model.reopenClass
  loadedSome: () ->
    all = @all()

    Em.RSVP.Promise (resolve) ->
      if all.get('length')
        Em.run.next -> resolve all
      else
        all.addObserver 'length', ->
          Em.run.next ->
            setTimeout ->
              resolve all
            , 200
          all.removeObserver @



App.Project = DS.Model.extend
  name: DS.attr 'string'
 
App.Issue = DS.Model.extend
  subject: DS.attr 'string'
  description: DS.attr 'string'
  status: DS.belongsTo 'App.IssueStatus'
  project: DS.belongsTo 'App.Project'
  author: DS.belongsTo 'App.User'
  assignedTo: DS.belongsTo 'App.User'
  updatedOn: DS.attr 'date'
  updatedOnSec: (->
    @get('updatedOn')?.valueOf()
  ).property('updatedOn')

  assignedToMe: (->
    Number(@get 'assignedTo.id') is App.user.get('serverId')
  ).property('assignedTo')

  
  statusId: (->
    Number @get 'status.id'
  ).property('status.id')

  isInWork: (->
    @get('statusId') is 2
  ).property('status.id')

  isWaiting: (->
    @get('statusId') in [4,8]
  ).property('status.id')

  isNewIssue: (->
    @get('statusId') is 1
  ).property('status.id')


  link: (->
    "#{ App.REDMINE_URL }issues/#{ @get 'id' }"
  ).property('id')


###
0: {is_default:true, name:Новая, id:1}

1: {name:В работе, id:2}

3: {name:Обратная связь, id:4}
7: {name:Отложена, id:8}

2: {name:Решена, is_closed:true, id:3}
4: {name:Закрыта, is_closed:true, id:5}
5: {name:Отклонена, is_closed:true, id:6}
6: {name:Готова к тестированию, is_closed:true, id:7}
###
#


# Adapter.map 'App.Issue',
  # status: { embedded: 'load' }
  # project: { embedded: 'load' }
  # author: { embedded: 'load' }
  # assignedTo: { embedded: 'load' }

App.IssueStatus = DS.Model.extend
  name: DS.attr 'string'
  isDefault: DS.attr 'boolean'
  isClosed: DS.attr 'boolean'

App.Membership = DS.Model.extend
  user: DS.belongsTo 'App.User'
  project: DS.belongsTo 'App.Project'
  # role: DS.belongsTo 'App.MembershipRole'

App.Membership.reopenClass
  url: (url, query) ->
    if query?.project_id isnt undefined
      url = url.replace('memberships', "/projects/#{ query.project_id }/memberships")
      delete query.project_id
    url

App.MembershipRole = DS.Model.extend
  name: DS.attr 'string'

# Adapter.map 'App.Membership',
#   role: { embedded: 'load' }
#   project: { embedded: 'load' }
#   user: { embedded: 'load' }


App.User = DS.Model.extend
  firstname: DS.attr 'string'
  lastname: DS.attr 'string'
  mail: DS.attr 'string'
  name: DS.attr 'string'
  serverId: DS.attr 'number'
  
  _name: (->
    r = @get 'name'
    unless r
      r = "#{ @get 'firstname' } #{ @get 'lastname' }"
    r
  ).property('name', 'firstname','lastname')

  gravatar: (->
    if @get 'mail'
      dig = hex_md5 @get('mail').toLowerCase().trim()
      "http://www.gravatar.com/avatar/#{ dig }.jpg?s=40&d=blank"
  ).property('mail')


App.store = DS.Store.create {}
  # revision: 12

App.store.set 'adapter', Adapter.create
  url: 'http://redmine.cursor.ru'
  # url: 'http://igor.cursor.ru:6789/redmine'

App.store.adapter.on 'error', (type) ->
  if type is 'Unauthorized'
    alert 'Неправильный API key!'
    App.auth.set 'apiKey', ''
    location.hash  = ''

 
# controllers
App.ProjectsController = Em.ArrayController.extend
  needs: 'laterIssues doneIssues nextIssues nowIssues'.w()


App.IndexController = Em.Controller.extend
  key: ''
  save: ->
    key = @get('key').replace(/[^a-z0-9]/,'')
    if key
      App.auth.set 'apiKey', key
      @target.transitionTo 'projects'


App.IssuesGroupController = Em.ArrayController.extend
  filteredContent: Ember.computed.alias 'content'
  sortProperties: 'updatedOnSec'.w()
  projectId: null
  adopt: (i) ->
    console.log 'You need to implement this!', i
  

  create: (i) ->
    console.log 'You need to implement this!', i
   
  assign: (i, m) ->
    i.set 'assignedTo', m.get('user')
    App.store.commit()


App.LaterIssuesController = App.IssuesGroupController.extend
  filteredContent: (->
    p = @get 'project'
    @get('content').filter (i) ->
      if i.get('project') is p
        i.get('isWaiting') or i.get('isNewIssue') and not i.get('assignedTo')

  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'project')


  create: (data) ->
    transaction = App.store.transaction()
    i = transaction.createRecord App.Issue, data
    i.set 'project', @get 'project'
    transaction.commit()


  adopt: (i) ->
    t = App.store.transaction()
    t.add i
    i.setProperties
      assignedTo: App.user
      status: App.IssueStatus.find(2)
    t.commit()



App.NowIssuesController = App.IssuesGroupController.extend
  filteredContent: (->
    p = @get 'project'
    @get('content').filter (i) ->
      if i.get('project') is p
        if App.get('.mode.selected') is 'my'
          i.get('assignedToMe') and i.get('isInWork')
        else
          i.get('assignedTo.id') isnt null and i.get('isInWork')


  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'project', 'App.mode.selected')
  
  adopt: (i) ->
    t = App.store.transaction()
    t.add i
    i.setProperties
      assignedTo: App.user
      status: App.IssueStatus.find(2)
    t.commit()



App.NextIssuesController = App.IssuesGroupController.extend
  filteredContent: (->
    p = @get 'project'
    @get('content').filter (i) ->
      if i.get('project') is p
        
        if App.get('mode.selected') is 'my'
          i.get('assignedToMe') and i.get('isNewIssue')
        else
          i.get('assignedTo.id') isnt null and i.get('isNewIssue')


  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'project', 'App.mode.selected')



App.DoneIssuesController = App.IssuesGroupController.extend
  adopt: (i) ->
    t = App.store.transaction()
    t.add i
    i.set 'assignedTo', App.user
    i.set 'status', App.IssueStatus.find(3)
    t.commit()

App.MembershipsController = Em.ArrayController.extend
  filteredContent: (->
    p = @get 'project'
    @get('content').filter (i) =>
      if i.get('project') is p
        i
  ).property('content.length','project')

# view
#

# Em.CollectionView.reopen
#   arrayWillChange: ->
#     try
#       @_super()
#     catch e
#       console.log 'ERROR: ', e


App.ApplicationView = Em.View.extend
  classNames: 'application container'.w()



App.ButtonGroup = Em.View.extend
  classNames: 'btn-group'.w()
  content: null
  value: null

  valueDidChange: (->
    v = @get 'value'
    Em.run.next =>
      @$('button').removeClass('active')
      @$('[value="'+v+'"]').addClass('active')
  ).observes('value')

  didInsertElement: ->
    @valueDidChange()

  click: (e) ->
    el = $(e.target)
    if el.is 'button'
      @set 'value', el.val()



App.IssuesGroup = Ember.Mixin.create DragNDrop.Droppable,
  classNames: 'issue-group'.w()
  templateName: 'issues_group'
  didDrop: (view) ->
    @get('controller').adopt view.get('content')

  canAdopt: (view) ->
    console.log 'dfdf!!',view , App.IssueView.detect view


App.LaterIssuesView = Em.View.extend App.IssuesGroup

App.DoneIssuesView = Em.View.extend App.IssuesGroup

App.NowIssuesView = Em.View.extend App.IssuesGroup

App.NextIssuesView = Em.View.extend App.IssuesGroup




App.IssueView = Em.View.extend DragNDrop.Dragable, DragNDrop.Droppable,
  classNames: 'issue'.w()
  didDrop: (user) ->
    @get('controller').assign @get('content'), user.get('content')


App.UserView = Em.View.extend DragNDrop.Dragable,
  classNames: 'user'.w()
  a: 1

App.TextArea = Ember.TextArea.extend
  keyUp: (e) ->
    if e.keyCode is 13 and not e.shiftKey
      text = @get('value').replace(/\n$/, '')
      @parse text
        
      # @get('controller').create @parse text
      @set 'value',''

  parse: (text) ->
    console.log text, text.match(/(?:\r\n|[\r\n]))/)

    i =
      subject: text
      description: ''
   


#init
App.set 'auth', Auth.create()
App.IssueStatus.find()
App.advanceReadiness()

# ca18a75a2d1241a7aac4207fecb5d1372233f169

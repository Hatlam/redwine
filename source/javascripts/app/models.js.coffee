#= require app/app

# models
get = Em.get
attr = Ember.attr
hasMany = Ember.hasMany
belongsTo = Ember.belongsTo


Ember.RecordArray.reopen
  whenLoaded: ->
    Em.RSVP.Promise (resolve, reject) =>
      if @get 'isLoaded'
        resolve @
      else
        @addObserver 'isLoaded', =>
          Em.run.next =>
            resolve @

Ember.Model.reopen
  camelizeKeys: true

  getBelongsTo: (key, type, meta) ->
    idOrAttrs = get(this, '_data.' + key)


    if Ember.isNone(idOrAttrs)
      return null

    if meta.options.embedded
      primaryKey = get(type, 'primaryKey')

      record = type.getFromRecordCache idOrAttrs[primaryKey]
      unless record
        record = type.create({ isLoaded: false })
        record.load(idOrAttrs[primaryKey], idOrAttrs)
    else
      record = type.find(idOrAttrs)

    record

  didCreateRecord: ->
    @_super()
    console.log 'did create', 111, @toJSON()
    @constructor._updateAll()

  didDeleteRecord: ->
    @_super()
    @constructor._updateAll()

  onDidLoad: (->
    @constructor._updateAll()
  ).observes('isLoaded')


  serializeBelongsTo: (key, meta) ->
    primaryKey = get(meta.getType(), 'primaryKey')
    id = @get(key + '.' + primaryKey)

    if meta.options.embedded
      record = @get(key)
      if record
        id or record.toJSON()
      else
        null
    else
      id
  

  toJSON: () ->
    # var key, meta,
    json = {}
    properties = {}
    properties = @getProperties(@attributes) if @attributes
    rootKey = get @constructor, 'rootKey'

    for key of properties
      meta = this.constructor.metaForProperty(key)
      if meta.type and meta.type.serialize
        json[this.dataKey(key)] = meta.type.serialize(properties[key])
      else if (meta.type && Ember.Model.dataTypes[meta.type])
        json[this.dataKey(key)] = Ember.Model.dataTypes[meta.type].serialize(properties[key])
      else
        json[this.dataKey(key)] = properties[key]
    

    if @relationships
      for key in @relationships
        meta = this.constructor.metaForProperty(key)
        relationshipKey = meta.options.key || key

        if meta.kind is 'belongsTo'
          data = this.serializeBelongsTo(key, meta)
           
          if typeof data is 'number'
            relationshipKey += '_id'

        else
          data = this.serializeHasMany(key, meta)

        json[relationshipKey] = data


    if rootKey
      jsonRoot = {}
      jsonRoot[rootKey] = json
      jsonRoot
    else
      json
    
 


Em.Model.reopenClass
  camelizeKeys: true

  _updateAll: ->
    unless @_all
      @_all = Em.ArrayProxy.create content: []

    #if not in all contains push
    # all push
    for k, m of @recordCache
      unless @_all.contains m
        @_all.pushObject m

    #if in all nut not cache
    #remove from all
    @_all

  all: ->
    unless @_all
      @_updateAll()
    @_all



Adapter = Em.RESTAdapter.extend
  parse: (json) ->
    delete json.limit
    delete json.total_count
    delete json.offset
    for k,v of json
      r = v
      break
    r


  _ajax: (url, params, method) ->
    settings = @ajaxSettings(url, method)

    new Ember.RSVP.Promise (resolve, reject) =>
      if params
        if method is "GET"
          settings.data = params
        else
          settings.contentType = "application/json; charset=utf-8"
          settings.data = JSON.stringify(params)

      settings.success = (json) =>
        parsed = @parse json
        Ember.run(null, resolve, parsed)
        null


      settings.error = (jqXHR, textStatus, errorThrown) ->
        # https://github.com/ebryn/ember-model/issues/202
        if jqXHR
          jqXHR.then = null


        Ember.run(null, reject, jqXHR)

      Ember.$.ajax(settings)


  ajaxSettings: (url, method) ->
    url: App.REDMINE_URL + url
    type: method
    headers:
      'X-Redmine-API-Key': App.auth.get 'apiKey'
    dataType: "json"
    contentType: 'application/json; charset=utf-8'
    crossDomain: true


App.Project = Em.Model.extend
  id: attr()
  name: attr()
  issueChangedOn: attr(Date)
  issueChangedOnSec: (->
    @get('issueChangedOn')?.valueOf() || 0
  ).property('issueChangedOn')


App.Project.url = "/projects"
App.Project.adapter = Adapter.create()

App.Issue = Em.Model.extend
  id: attr()
  subject: attr()
  description: attr()
  status: belongsTo('App.IssueStatus', embedded: true, key: 'status')
  priority: belongsTo('App.IssuePriority', embedded: true, key: 'priority')
  project: belongsTo('App.Project', embedded: true, key: 'project')
  # author: belongsTo('App.User')
  assignedTo: belongsTo('App.User', key: 'assigned_to', embedded: true)
  
  fixedVersion: belongsTo('App.Version')

  # updatedOn: attr(Date)
  # updatedOnSec: (->
  #   @get('updatedOn')?.valueOf()
  # ).property('updatedOn')

  assignedToMe: (->
    @get('assignedTo') is App.user
  ).property('assignedTo')

  isInWork: (->
    Number(@get 'status.id') is 2
  ).property('status.id')

  isWaiting: (->
    Number(@get 'status.id') in [4,8]
  ).property('status.id')

  isNewIssue: (->
    Number(@get 'status.id') is 1
  ).property('status.id')


  link: (->
    "#{ App.REDMINE_URL }/issues/#{ @get 'id' }"
  ).property('id')


Adapter2 = Adapter.extend
  didCreateRecord: (record, data) ->
    @_super record, 'issue': data

App.Issue.url = "/issues"
App.Issue.adapter = Adapter2.create()
App.Issue.rootKey = 'issue'


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



App.IssuePriority = Em.Model.extend
  # id: attr()
  name: attr()
  isDefault: attr()
  slug: (-> 'priority-' + @get 'id' ).property('id')


App.IssuePriority.url = '/enumerations/issue_priorities'
App.IssuePriority.adapter = Adapter.create()



App.IssueStatus = Em.Model.extend
  id: attr()
  name: attr()
  isDefault: attr()
  isClosed: attr()

App.IssueStatus.url = '/issue_statuses'
App.IssueStatus.adapter = Adapter.create()


App.Membership = Em.Model.extend
  user: belongsTo('App.User', key: 'user', embedded: true)
  project: belongsTo 'App.Project'
  role: belongsTo 'App.MembershipRole'


App.Membership.url = '/projects/$project_id$/memberships'
App.Membership.adapter = Adapter.create
  findQuery: (klass, records, params) ->
    url = @buildURL(klass)
    url = url.replace '$project_id$', params.project_id
    delete params.project_id

    @ajax(url, params).then (data) =>
      @didFindQuery(klass, records, params, data)
      records


App.MembershipRole = Em.Model.extend
  name: attr()


App.Version = Em.Model.extend
  id: attr()
  name: attr()
  status: attr()
  description: attr()
  dueDate: attr(Date)
  project: belongsTo('App.Project', embedded: true)
    
App.Version.url = '/projects/$project_id$/versions'
App.Version.adapter = Adapter.create
  findQuery: (klass, records, params) ->
    url = @buildURL(klass)
    url = url.replace '$project_id$', params.project_id
    delete params.project_id

    @ajax(url, params).then (data) =>
      @didFindQuery(klass, records, params, data)
      records





App.User = Em.Model.extend
  id: attr()
  firstname: attr()
  lastname: attr()
  mail: attr()
  name: attr()
 
  _name: (->
    r = @get 'name'
    unless r
      r = "#{ @get 'firstname' } #{ @get 'lastname' }"
    r
  ).property('name', 'firstname','lastname')

  gravatar: (->
    if @get 'mail'
      dig = hex_md5 @get('mail').toLowerCase().trim()
      "http://www.gravatar.com/avatar/#{ dig }.jpg?rating=PG&s=80&d=blank"
  ).property('mail')



App.User.url = "/users"
App.User.rootKey = 'user'
App.User.adapter = Adapter.create
  findQuery: (klass, records, params) ->
    url = @buildURL(klass)
     
    isCurrent = params.current
    if isCurrent
      url = url.replace 'users', 'users/current'
      params = {}

    @ajax(url, params).then (data) =>
      if isCurrent
        data = [data]
      @didFindQuery(klass, records, params, data)
      records
    

#= require app/routes

 
# controllers
App.ProjectsController = Em.ArrayController.extend
  needs: 'laterIssues doneIssues nextIssues nowIssues project'.w()
  sortProperties: 'name'.w()
  # sortAscending: false
  
  createIssue: (data) ->
    i = App.Issue.create data
    i.set 'project', @get 'controllers.project.content'
    i.save()

App.ProjectController = Em.ObjectController.extend
  a: 1


App.IndexController = Em.Controller.extend
  key: ''
  save: ->
    key = @get('key').replace(/[^a-z0-9]/,'')
    if key
      App.auth.set 'apiKey', key
      @target.transitionTo 'projects'


App.IssuesGroupController = Em.ArrayController.extend
  # sortFunction: (a,b) ->
  #   # return 0 if x is y
  #   # return x < y ? -1 : 1;
  #   console.log 'sd!!!', a, b
  #   a - b
  
  adopt: (i) ->
    console.log @, '.adopt: You need to implement this!', i
  
  dropOnIssue: (issue, o) ->
    #assign
    if App.User.detectInstance o
      issue.set('assignedTo', o)
      issue.save()
    
    if App.IssuePriority.detectInstance o
      issue.set 'priority', o
      issue.save()


App.LaterIssuesController = App.IssuesGroupController.extend
  arrangedContent: (->
    p = @get 'project'
    c = @get('content').filter (i) ->

      if i.get('project') is p
        i.get('isWaiting') or i.get('isNewIssue') and not i.get('assignedTo')
    
    c = c.slice()
    c.sort (a,b) ->
      b.get('priority.id') - a.get('priority.id')

  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'content.@each.priority.id','App.mode.selected')

  adopt: (i) ->
    if i.get('assignedTo')
      # set 'later'
      i.set('status', App.IssueStatus.find(8))
    i.save()


App.NowIssuesController = App.IssuesGroupController.extend
  arrangedContent: (->
    p = @get 'project'
    c = @get('content').filter (i) ->
      if i.get('project') is p
        if App.get('.mode.selected') is 'my'
          i.get('assignedToMe') and i.get('isInWork')
        else
          i.get('assignedTo.id') isnt null and i.get('isInWork')

    c = c.slice()
    c.sort (a,b) ->
      b.get('priority.id') - a.get('priority.id')

  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'content.@each.priority.id','App.mode.selected')
  
  adopt: (i) ->
    if App.get 'mode.isMy'
      i.set('assignedTo', App.user)
    # set 'in work'
    i.set('status', App.IssueStatus.find(2))
    i.save()



App.NextIssuesController = App.IssuesGroupController.extend
  arrangedContent: (->
    p = @get 'project'
    c = @get('content').filter (i) ->
      if i.get('project') is p
        
        if App.get('mode.selected') is 'my'
          i.get('assignedToMe') and i.get('isNewIssue')
        else
          i.get('assignedTo.id') isnt null and i.get('isNewIssue')

    c = c.slice()
    c.sort (a,b) ->
      b.get('priority.id') - a.get('priority.id')

  ).property('content.@each.status.id','content.@each.assignedTo.id' , 'content.@each.priority.id', 'App.mode.selected')


  adopt: (i) ->
    if App.get 'mode.isMy'
      i.set('assignedTo', App.user)
    # set 'new'
    i.set('status', App.IssueStatus.find(1))
    i.save()


App.DoneIssuesController = App.IssuesGroupController.extend
  arrangedContent: (->
    p = @get 'project'
    c = @get('content').filter (i) ->
      if i.get('project') is p
        
        if App.get('mode.selected') is 'my'
          i.get('assignedToMe') and i.get('status.isClosed')
        else
          i.get('status.isClosed')

    c = c.slice()
    c.sort (a,b) ->
      b.get('priority.id') - a.get('priority.id')

  ).property('content.@each.status.id','content.@each.assignedTo.id' ,  'content.@each.priority.id','App.mode.selected')


  adopt: (i) ->
    if App.get 'mode.isMy'
      i.set('assignedTo', App.user)
    i.set 'status', App.IssueStatus.find(3)
    i.save()


App.UsersController = Em.ArrayController.extend
  arrangedContent: (->
    a = Em.ArrayProxy.create content: []

    @get('memberships')?.forEach (m) ->
      a.pushObject m.get('user')

    # project = @get 'project'
    # users = @get 'content'
      
    a.uniq()
  ).property('content.length', 'project', 'memberships.length')


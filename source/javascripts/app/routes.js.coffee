#= require app/app
#= require app/models


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
    unless App.auth.get 'apiKey'
      @transitionTo 'index'


App.ProjectsRoute = Em.Route.extend
  model: ->
    App.Project.find()

  setupController: (controller, model) ->
    @_super controller, model

    controller.set 'priority', App.IssuePriority.find()

    App.IssueStatus.find()
    i = App.Issue.all()
    @controllerFor('laterIssues').set 'content', i
    @controllerFor('nowIssues').set 'content', i
    @controllerFor('nextIssues').set 'content', i
    @controllerFor('doneIssues').set 'content', i

    @controllerFor('users').set 'content', App.User.find()


App.ProjectRoute = Em.Route.extend
  setupController: (controller, model) ->
    @_super controller, model
    

    @controllerFor('laterIssues').set 'project', model
    @controllerFor('nowIssues').set 'project', model
    @controllerFor('nextIssues').set 'project', model
    @controllerFor('doneIssues').set 'project', model
    @controllerFor('users').set 'project', model


    App.auth.ready.then =>
      @controllerFor('users').set 'memberships', App.Membership.find(project_id: model.get 'id')
      @controllerFor('projects').set 'versions', App.Version.find(project_id: model.get 'id', status: 'open')

      openedIssues = App.Issue.find
        project_id: model.get('id')
        status_id: 'opened'
        limit: 100

      doneIssues = App.Issue.find
        project_id: model.get('id')
        status_id: 'closed'
        # assigned_to_id: App.user.get('id')
        # limit: 10
        # sort: 'id:desc'

 
  # request: ->
    



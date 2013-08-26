
# view
#

Em.LinkView.reopen
  draggable: 'false'


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
    if App.IssueView.detectInstance view
      @get('controller').adopt view.get('issue')

  canAdopt: (view) ->
    App.IssueView.detectInstance view


App.LaterIssuesView = Em.View.extend App.IssuesGroup,
  title: 'Потом'
  tip: 'новые неназначенные или обратная связь или отложенная'

App.DoneIssuesView = Em.View.extend App.IssuesGroup,
  title: 'Готово'
  tip: 'назначены, закрытые или решена или к тестированию или отклонена, последние 5'

App.NowIssuesView = Em.View.extend App.IssuesGroup,
  title: 'Сейчас'
  tip: 'назначены, в работе'

App.NextIssuesView = Em.View.extend App.IssuesGroup,
  title: 'Далее'
  tip: 'назначены, новые'



App.IssueView = Em.View.extend DragNDrop.Dragable, DragNDrop.Droppable,
  classNames: 'issue'.w()
  classNameBindings: 'issue.priority.slug'.w()
  issue: null

  didDrop: (view) ->
    @get('controller').dropOnIssue @get('issue'), view.get('content')
  
  didInsertElement: ->
    if  (new Date).valueOf() - @get('content.updatedOnSec') < 5000
      @$().effect('highlight')

  canAdopt: (view) ->
    u = App.UserView.detectInstance view
    # v = App.VersionView.detectInstance view
    p = App.PriorityView.detectInstance view
    u or p

App.UserView = Em.View.extend DragNDrop.Dragable,
  classNames: 'user'.w()
  a: 1

App.VersionView = Em.View.extend DragNDrop.Dragable,
  classNames: 'item'

App.PriorityView = Em.View.extend DragNDrop.Dragable,
  classNames: 'item'
  classNameBindings: 'content.slug'.w()
  attributeBindings: 'title'.w()
  titleBinding: 'content.name'




App.TextArea = Ember.TextArea.extend
  keyUp: (e) ->
    if e.keyCode is 13 and (e.ctrlKey)
      v = @get('value').trim()
      if v.length
        @get('controller').createIssue @parse v
        @set 'value',''

  parse: (text) ->
    text = text.replace(/\n$/, '')
    text = text.split(/\n/)
    if text[1]
      unless text[1].match(/\S+/)
        # console.log 'second line', text[1]?.match(/\S+/)
        text.splice(1,1)

    i =
      subject: text.shift()
      description: text.join('\n').replace(/^\n/,'')
   



###

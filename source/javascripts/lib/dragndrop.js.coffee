window.DragNDrop = Ember.Namespace.create()



DragNDrop.Dragable = Ember.Mixin.create
  attributeBindings: 'draggable'
  draggable: 'true'
  dragStart: (event) ->
    # event.dataTransfer.effectAllowed = 'copy'
    DragNDrop.set 'current', @

  wasDropped: ->
    # @destroy()


DragNDrop.Droppable = Ember.Mixin.create
  classNameBindings: 'hasDragOver:drag-over'.w()
  hasDragOver: false

  dragEnter: Em.aliasMethod('dragOver')
  dragOver: (event) ->
    # event.dataTransfer.dropEffect = 'move';  # See the section on the DataTransfer object.

    view = @viewFromEvent event
    can = @canAdopt DragNDrop.get('current')
    @set 'hasDragOver', true
    
    event.stopImmediatePropagation()

    if can
      event.preventDefault()
      false

    
  
  dragLeave: ->
    @set 'hasDragOver', false


  # mouseLeave: (event) ->
  #   console.log 'sdsd mouse leave', 1
    # to = event.originalEvent.toElement
    # has = !!@$().has(to).length
    # notLeave = has or @$()[0] is to


    # unless notLeave
    # @set 'hasDragOver', false
    #   event.preventDefault()
    # console.log 'real leave()', @$()[0], to, has, notLeave


  viewFromEvent: (event) ->
    DragNDrop.get 'current'

  canAdopt: (view) ->
    true

  drop: (event) ->
    @set 'hasDragOver', false
    view = @viewFromEvent event
    @didDrop view
    view.wasDropped @
    DragNDrop.set 'current', null
    event.preventDefault()
    false

  didDrop: (view) ->
    console.log 'didDrop', view



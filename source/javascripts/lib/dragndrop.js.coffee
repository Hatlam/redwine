window.DragNDrop = Ember.Namespace.create()


DragNDrop.Dragable = Ember.Mixin.create
  attributeBindings: 'draggable'
  draggable: 'true'
  dragStart: (event) ->
    dataTransfer = event.originalEvent.dataTransfer
    dataTransfer.effectAllowed = 'copy'
    dataTransfer.setData('viewId', this.get('elementId'))

  wasDropped: ->
    # @destroy()


DragNDrop.Droppable = Ember.Mixin.create
  classNameBindings: 'hasDragOver:drag-over'.w()
  hasDragOver: false


  dragEnter: (event) ->
    event.preventDefault()
    @set 'hasDragOver', true

  dragLeave: (event) ->
    event.preventDefault()
    # unless event.originalEvent.srcElement is @$()[0]
    @set 'hasDragOver', false

  dragOver: (event) ->
    event.preventDefault()
    # event.dataTransfer.dropEffect = 'move';  # See the section on the DataTransfer object.
    false

  viewFromEvent: (event) ->
    viewId = event.originalEvent.dataTransfer.getData('viewId')
    view = Ember.View.views[viewId]


  canAdopt: (view) ->
    true

  drop: (event) ->
    @set 'hasDragOver', false

    view = @viewFromEvent event
    @didDrop view
    if @canAdopt view
      view.wasDropped @
      event.preventDefault()
      false
    else
      true

  didDrop: (view) ->
    console.log 'didDrop', view



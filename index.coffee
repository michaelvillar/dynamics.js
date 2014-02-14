roundf = (float, decimals) ->
  factor = Math.pow(10, decimals)
  Math.round(float * factor) / factor

class BrowserSupport
  @transform: ->
    @withPrefix("transform")

  @keyframes: ->
    return "-webkit-keyframes" if document.body.style.webkitAnimation != undefined
    return "-moz-keyframes" if document.body.style.mozAnimation != undefined
    "keyframes"

  @withPrefix: (property) ->
    prefix = @prefixFor(property)
    return "-#{prefix.toLowerCase()}-#{property}" if prefix != ''
    property

  @prefixFor: (property) ->
    propArray = property.split('-')
    propertyName = ""
    for prop in propArray
      propertyName += prop.substring(0, 1).toUpperCase() + prop.substring(1)
    for prefix in [ "Webkit", "Moz" ]
      k = prefix + propertyName
      if document.body.style[k] != undefined
        return prefix
    ''

class Graph
  constructor: (canvas) ->
    @points = null
    @tween = null
    @canvas = canvas
    @ctx = canvas.getContext('2d')

    @r = window.devicePixelRatio || 1
    if @r
      canvas.width = canvas.width * @r
      canvas.height = canvas.height * @r
      canvas.style[BrowserSupport.prefixFor('transform-origin') + 'TransformOrigin'] = "0 0"
      canvas.style[BrowserSupport.prefixFor('transform') + 'Transform'] = 'scale('+(1 / @r)+')'

    @canvas.addEventListener 'mousedown', @canvasMouseDown
    @canvas.addEventListener 'mousemove', @canvasMouseMove
    @canvas.addEventListener 'mouseup', @canvasMouseUp
    window.addEventListener 'keyup', @canvasKeyUp

  draw: =>
    r = window.devicePixelRatio
    w = @canvas.width
    h = @canvas.height

    step = 0.001

    @ctx.clearRect(0,0,w,h)

    @ctx.strokeStyle = '#D5E6F8'
    @ctx.lineWidth = 1
    @ctx.beginPath()
    @ctx.moveTo(0, 0.67 * h)
    @ctx.lineTo(w, 0.67 * h)
    @ctx.stroke()

    @ctx.beginPath()
    @ctx.moveTo(0, 0.34 * h)
    @ctx.lineTo(w, 0.34 * h)
    @ctx.stroke()

    @tween.init()
    graphes = []
    colors = [ '#007EFF' ]
    defaultColor = '#D5E6F8'
    colorI = 0
    while args = @tween.next(step)
      for i in [1..args.length]
        graphes[i - 1] ||= {
          points: []
        }
        graphes[i - 1].points.push [args[0], args[i]]
      if args[0] >= 1
        break

    for graph in graphes
      color = defaultColor
      color = colors[colorI] if colorI < colors.length
      graph.color = color
      graph.index = colorI
      colorI += 1

    for graph in graphes.reverse()
      points = graph.points
      @ctx.beginPath()
      @ctx.strokeStyle = graph.color
      @_drawCurve(points)
      if graph.index == 0
        @ctx.lineWidth = (2 * r)
      else
        @ctx.lineWidth = (1 * r)
      @ctx.stroke()

    if @points
      for point in @points
        # Draw line between point and each control points
        for controlPoint in point.controlPoints
          @ctx.beginPath()
          @ctx.strokeStyle = colors[0]
          @ctx.lineWidth = 1
          coords = @pointCoordinates(point)
          @ctx.moveTo(coords.x, coords.y)
          coordsControlPoint = @pointCoordinates(controlPoint)
          @ctx.lineTo(coordsControlPoint.x, coordsControlPoint.y)
          @ctx.stroke()

      for point in @points
        # Draw point
        @ctx.beginPath()
        @ctx.strokeStyle = if @selectedPoint == point then 'black' else colors[0]
        @ctx.fillStyle = 'white'
        @ctx.lineWidth = 2 * r
        coords = @pointCoordinates(point)
        @ctx.arc(coords.x, coords.y, 5 * r, 0, Math.PI*2, true)
        @ctx.fill()
        @ctx.stroke()

        # Draw control points
        for controlPoint in point.controlPoints
          @ctx.beginPath()
          @ctx.strokeStyle = if @selectedPoint == controlPoint then 'black' else colors[0]
          @ctx.fillStyle = 'white'
          @ctx.lineWidth = 1 * r
          coords = @pointCoordinates(controlPoint)
          @ctx.arc(coords.x, coords.y, 3 * r, 0, Math.PI*2, true)
          @ctx.fill()
          @ctx.stroke()

  locationFromEvent: (e) =>
    { x: e.layerX, y: e.layerY }

  isLocationAroundCenter: (location, center, size) =>
    r = window.devicePixelRatio
    center = { x: center.x / r, y: center.y / r }
    (location.x >= center.x - size / 2) and (location.x <= center.x + size / 2) and (location.y >= center.y - size / 2) and (location.y <= center.y + size / 2)

  pointFromLocation: (location) =>
    return null if !@points or @points.length < 2
    for point in @points
      if point != @points[0]
        return point if @isLocationAroundCenter(location, @pointCoordinates(point), 14)
      for controlPoint in point.controlPoints
        return controlPoint if @isLocationAroundCenter(location, @pointCoordinates(controlPoint), 10)
    null

  canvasMouseDown: (e) =>
    location = @locationFromEvent(e)
    point = @pointFromLocation(location)
    @selectedPoint = point
    unless @selectedPoint
      converted = @convertFromCoordinates(location)
      @selectedPoint = {
        x: converted.x,
        y: converted.y,
        controlPoints: [
          { x: converted.x - 0.1, y: converted.y },
          { x: converted.x + 0.1, y: converted.y }
        ]
      }
      @insertPoint(@selectedPoint)
    @draw()
    @dragging = true

  canvasMouseMove: (e) =>
    return unless @selectedPoint
    return unless @dragging
    location = @locationFromEvent(e)
    point = @convertFromCoordinates(location)
    if @selectedPoint == @points[@points.length - 1]
      point.x = 1
      point.y = Math.min(1, Math.max(0, Math.round(point.y)))
    if @selectedPoint.controlPoints
      for controlPoint in @selectedPoint.controlPoints
        controlPoint.x = roundf(controlPoint.x + point.x - @selectedPoint.x, 3)
        controlPoint.y = roundf(controlPoint.y + point.y - @selectedPoint.y, 3)
    @selectedPoint.x = point.x
    @selectedPoint.y = point.y
    @draw()

  canvasMouseUp: (e) =>
    @dragging = false
    @pointsChanged?()

  canvasKeyUp: (e) =>
    return unless @selectedPoint
    if e.keyCode == 8
      # Cannot delete control points
      return unless @selectedPoint.controlPoints
      # Cannot delete first or last
      return if @selectedPoint == @points[0] or @selectedPoint == @points[@points.length - 1]

      e.preventDefault()
      @points.splice(@points.indexOf(@selectedPoint), 1)
      @selectedPoint = null
      @pointsChanged?()

  pointCoordinates: (point) ->
    w = @canvas.width
    h = @canvas.height
    { x: point.x * w, y: (0.67 * h) - (point.y * 0.33 * h) }

  convertFromCoordinates: (location) ->
    r = window.devicePixelRatio
    w = @canvas.width
    h = @canvas.height
    { x: roundf(location.x / w * r, 3), y: roundf(((0.67 * h) - (location.y * r)) / (0.33 * h), 3) }

  insertPoint: (toInsertPoint) =>
    index = 0
    for i, point of @points
      if point.x >= toInsertPoint.x
        index = i
        break
    @points.splice(index, 0, toInsertPoint)

  _drawCurve: (points) =>
    r = window.devicePixelRatio
    w = @canvas.width
    h = @canvas.height

    for point in points
      [t, v] = point
      if t == 0
        @ctx.moveTo(t * w,h - ((0.33 + (v * 0.33)) * h))
      else
        @ctx.lineTo(t * w,h - ((0.33 + (v * 0.33)) * h))

class UIProperty
  constructor: (@options = {}) ->
    @el = document.createElement('div')

    @label = document.createElement('label')
    @label.innerHTML = @options.property

    @valueEl = document.createElement('div')
    @valueEl.classList.add 'value'
    @valueEl.classList.add options.property

    @el.appendChild(@label)
    @el.appendChild(@valueEl)

    @valueEl.innerHTML = @options.value

  setValue: (value) =>
    @options.value = value
    @valueEl.innerHTML = @options.value

class UISlider
  constructor: (@options = {}) ->
    @options.min ||= 0
    @options.max ||= 1000
    @options.value = 10 if @options.value == undefined

    @width = 205 - 11

    @el = document.createElement('div')

    @label = document.createElement('label')
    @label.innerHTML = @options.property

    @valueEl = document.createElement('div')
    @valueEl.classList.add 'value'
    @valueEl.classList.add options.property

    @slider = document.createElement('div')
    @slider.classList.add 'slider'
    @slider.classList.add options.property

    @bar = document.createElement('div')
    @bar.classList.add('bar')
    @control = document.createElement('div')
    @control.classList.add('control')

    @slider.appendChild(@bar)
    @slider.appendChild(@control)

    @el.appendChild(@label)
    @el.appendChild(@valueEl)
    @el.appendChild(@slider)

    @valueEl.innerHTML = @options.value

    @_updateLeftFromValue()

    @control.addEventListener('mousedown', @_controlMouseDown)

  value: =>
    @options.value

  _updateLeftFromValue: =>
    @control.style.left = (@options.value - @options.min) / (@options.max - @options.min) * @width + "px"

  _controlMouseDown: (e) =>
    @dragging = true
    @startPoint = [e.pageX, e.pageY]
    @startLeft = parseInt(@control.style.left || 0)
    window.addEventListener('mousemove', @_windowMouseMove)
    window.addEventListener('mouseup', @_windowMouseUp)

  _windowMouseMove: (e) =>
    return unless @dragging
    dX = e.pageX - @startPoint[0]
    newLeft = (@startLeft + dX)
    if newLeft > @width
      newLeft = @width
    else if newLeft < 0
      newLeft = 0

    @options.value = Math.round(newLeft / @width * (@options.max - @options.min) + @options.min)
    @valueEl.innerHTML = @options.value

    @onUpdate?()

    @control.style.left = newLeft + "px"

  _windowMouseUp: (e) =>
    @dragging = false
    window.removeEventListener('mousemove', @_windowMouseMove)
    window.removeEventListener('mouseup', @_windowMouseUp)

class Tools
  @valuesFromURL = =>
    url = (document.location.toString() || '').split('#')
    values = {}
    if url.length > 1
      query = url[1]
      for arg in query.split(',')
        [k, v] = arg.split('=')
        values[k] = decodeURIComponent(v)
    values

  @saveValues: (args) =>
    argsString = ''
    for k, v of args
      argsString += "," unless argsString == ''
      argsString += "#{k}=#{encodeURIComponent(v)}"

    currentURL = (document.location.toString() || '').split('#')[0]
    document.location = currentURL + "#" + argsString

class App
  constructor: ->
    @dynamicsClasses = []
    for k, v of Dynamics.Types
      @dynamicsClasses.push v

    @currentCircle = null
    @codeSection = document.querySelector('section.code')
    @track = document.querySelector('div.track')
    @select = document.querySelector('select.dynamics')
    @dynamicsClass = @dynamicsClasses[0]
    for aDynamicsClass in @dynamicsClasses
      if aDynamicsClass.name == Tools.valuesFromURL().dynamic
        @dynamicsClass = aDynamicsClass
      option = document.createElement('option')
      option.innerHTML = "Dynamics.Types.#{aDynamicsClass.name}"
      option.value = aDynamicsClass.name
      option.selected = aDynamicsClass == @dynamicsClass
      @select.appendChild option
    @select.addEventListener 'change', @selectDidChange
    @graph = new Graph(document.querySelector('canvas'))
    @sliders = []
    @properties = []

    @updateOptions()
    @update()

  selectDidChange: =>
    name = @select.options[@select.selectedIndex].value
    @dynamicsClass = eval("Dynamics.Types.#{name}")
    @updateOptions()
    @update()

  updateOptions: =>
    tweenOptionsEl = document.querySelector('.options')
    tweenOptionsEl.innerHTML = ''
    values = Tools.valuesFromURL()
    @sliders = []
    @properties = []
    @points = null

    for property, config of @dynamicsClass.properties
      if config.type == 'points'
        if values.points
          try
            @points = JSON.parse(values.points)
          catch e
            @points = config.default
        else
          @points = config.default
      else if config.editable == false
        uiProperty = new UIProperty({
          value: 'N/A',
          property: property
        })
        tweenOptionsEl.appendChild(uiProperty.el)
        @properties.push(uiProperty)
      else
        slider = new UISlider({
          min: config.min,
          max: config.max,
          value: values[property] || config.default,
          property: property
        })
        tweenOptionsEl.appendChild(slider.el)
        @sliders.push slider
    for slider in @sliders
      slider.onUpdate = @update

  update: =>
    args = {}
    for slider in @sliders
      args[slider.options.property] = slider.value()
    args['dynamic'] = @dynamicsClass.name if @dynamicsClass
    args['points'] = JSON.stringify(@points) if @points
    Tools.saveValues(args)
    clearTimeout @animationTimeout if @animationTimeout
    @animationTimeout = setTimeout(@animate, 400)

    @createDynamic()

    @graph.tween = @dynamic.tween()
    @graph.points = @points
    @graph.pointsChanged = @update
    @graph.draw()

    for uiProperty in @properties
      uiProperty.setValue(@dynamic.tween()[uiProperty.options.property]())

    @updateCode()

  updateCode: =>
    translateX = if @dynamicsClass != Dynamics.Types.SelfSpring then 350 else 50
    options = "&nbsp;&nbsp;<strong>type</strong>: Dynamics.Types.#{@dynamicsClass.name}"
    for slider in @sliders
      options += ",\n" if options != ''
      options += "&nbsp;&nbsp;<strong>#{slider.options.property}</strong>: #{slider.value()}"
    if @points
      pointsValue = JSON.stringify(@points)
      options += ",\n&nbsp;&nbsp;<strong>points</strong>: #{pointsValue}"
    code = '''new <strong>Dynamics.Animation</strong>(document.getElementId("circle"), {
&nbsp;&nbsp;<strong>translateX</strong>: 0
}, {
&nbsp;&nbsp;<strong>translateX</strong>: ''' + translateX + '''

}, {

''' + options + '''

}).start();'''
    @codeSection.innerHTML = code

  createDynamic: =>
    options = { }
    for slider in @sliders
      options[slider.options.property] = slider.value()
    options.points = @points if @points
    if @dynamicsClass != Dynamics.Types.SelfSpring
      from = { translateX: 0 }
      to = { translateX: 350 }
    else
      from = { translateX: 0 }
      to = { translateX: 50 }
    if !@currentCircle
      @currentCircle = document.createElement('div')
      @currentCircle.classList.add('circle')
      @currentCircle.addEventListener 'click', =>
        @animate()
      new Dynamics.Animation(@currentCircle, {
        scale: 0
      }, {
        scale: 1
      }, {
        type: Dynamics.Types.Spring,
        frequency: 0,
        friction: 600,
        anticipationStrength: 100,
        anticipationSize: 10,
        duration: 1000
      }).start()
      document.querySelector('section.demo').appendChild(@currentCircle)
    circle = @currentCircle
    options.type = @dynamicsClass
    @dynamic = dynamic = new Dynamics.Animation(circle, from, to, options)
    shouldDeleteCircle = !dynamic.returnsToSelf
    options.complete = =>
      return unless shouldDeleteCircle
      @createDynamic()
      new Dynamics.Animation(circle, {
        translateX: if !dynamic.returnsToSelf then 350 else 0,
        scale: 1
      }, {
        translateX: if !dynamic.returnsToSelf then 350 else 0,
        scale: 0
      }, {
        type: Dynamics.Types.Spring,
        frequency: 0,
        friction: 600,
        anticipationStrength: 100,
        anticipationSize: 10,
        duration: 1000,
        complete: =>
          circle.parentNode.removeChild(circle)
      }).start()
    if @dynamicsClass != Dynamics.Types.SelfSpring
      @track.classList.remove('tiny')
    else
      @track.classList.add('tiny')

  animate: =>
    @createDynamic()
    @dynamic.start()
    if !@dynamic.returnsToSelf
      @currentCircle = null

document.addEventListener "DOMContentLoaded", ->
  app = new App
, false

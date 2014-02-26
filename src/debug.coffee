css = '''
div#DynamicsInteractivePanel, div#DynamicsInteractivePanel * {
  margin: 0;
  padding: 0;
  border: 0;
  font-family: "HelveticaNeue", "Helvetica Neue", Helvetica, Arial;
  color: #000;
}
div#DynamicsInteractivePanel {
  position: absolute;
  top: 10px;
  left: 10px;
  width: 584px;
  height: 378px;
  padding: 0 0 10px 0;
  border-radius: 8px;
  box-shadow: 0 4px 30px rgba(0, 0, 0, .15),
              0 2px 10px rgba(0, 0, 0, .25);
  background: white;
  z-index: 10000000;
}
div#DynamicsInteractivePanel > div.title {
  position: absolute;
  padding: 6px 0;
  width: 100%;
  color: #394E6E;
  font-size: 13px;
  text-align: center;
  user-select: none;
  -webkit-user-select: none;
  cursor: default;
  font-family: "HelveticaNeueMedium", "HelveticaNeue-Medium", "Helvetica Neue Medium", "HelveticaNeue", "Helvetica Neue", Helvetica, Arial
}
div#DynamicsInteractivePanel > div.content {
  position: absolute;
  top: 28px;
  left: 10px;
  right: 10px;
}
div#DynamicsInteractivePanel > div.content > div.graph {
  position: relative;
  height: 350px;
  width: 350px;
  overflow: hidden;
  user-select: none;
  -webkit-user-select: none;
  cursor: default;
}
div#DynamicsInteractivePanel > div.content > div.graph > span {
  font-size: 10px;
  color: #8096B1;
  position: absolute;
  left: 2px;
  margin-top: -5px;
}
div#DynamicsInteractivePanel > div.content > div.graph > span.index1 { top: 112px; }
div#DynamicsInteractivePanel > div.content > div.graph > span.index0 { top: 228px; }
div#DynamicsInteractivePanel > div.content > div.graph > canvas {
  background: #F4F9FF;
}
div#DynamicsInteractivePanel > div.content > div.settings {
  position: absolute;
  top: 10px;
  right: 0;
  width: 205px;
  -webkit-user-select: none;
  -moz-select: none;
  user-select: none;
}
div#DynamicsInteractivePanel > div.content > div.settings select {
  -webkit-appearance: none;
  -moz-appearance: none;
  appearance: none;
  border: none;
  width: 100%;
  height: 27px;
  border-radius: 5px;
  padding: 6px 20px 6px 6px;
  color: #fff;
  font-size: 13px;
  margin-bottom: 15px;
  text-align: left;
  background: #007EFF url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAICAYAAAAx8TU7AAAAOUlEQVQIHWNgAIL///8bAPFpEA3igwR4gPgWEIMAiOYBCS4C8ZDAIrBq4gigNkztQEFMi6AuQHESAPMeXiEMiWfpAAAAAElFTkSuQmCC) no-repeat 190px 9px;
  background-size: 5px 8px;
}
@media only screen and (-webkit-min-device-pixel-ratio: 1.5), only screen and (min--moz-device-pixel-ratio: 1.5), only screen and (min-device-pixel-ratio: 1.5)
{
  div#DynamicsInteractivePanel > div.content > div.settings select {
    background-image: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAQCAYAAAAvf+5AAAAAeklEQVQoFc2SwQ2AIAxFGYALo7CY7OQGMo6beMJXQ5PWYOAoyael/5FAIQQzWmsJHV3JWD4FqEhH9W5f4RYlTCwOxsjoMoCmUssPTBLRqc4gihcD0z4w36XdHeGvi+XLAK61R24KPG+4tgR49ISb+i4Czz+F7AD8/GY3j4s9N2crn9sAAAAASUVORK5CYII=);
  }
}
div#DynamicsInteractivePanel > div.content > div.settings select:focus {
  outline: none;
  background-color: #394E6E;
}
div#DynamicsInteractivePanel > div.content > div.settings label {
  float: left;
  color: #394E6E;
  font-size: 13px;
}
div#DynamicsInteractivePanel > div.content > div.settings .value {
  float: right;
  color: #394E6E;
  font-size: 13px;
  margin-bottom: 4px
}
div#DynamicsInteractivePanel > div.content > div.settings div.slider {
  clear: both;
  position: relative;
  width: 100%;
  height: 20px;
  margin-bottom: 7px;
  user-select: none;
  -webkit-user-select: none;
  cursor: default;
}
div#DynamicsInteractivePanel > div.content > div.settings div.slider .bar {
  position: absolute;
  top: 4px;
  left: 0;
  background: #e0effe;
  height: 3px;
  width: 100%;
  border-radius: 3px;
}
div#DynamicsInteractivePanel > div.content > div.settings div.slider .control {
  position: absolute;
  top: 0;
  left: 0;
  background: #fff;
  height: 7px;
  width: 7px;
  border: 2px solid #007EFF;
  border-radius: 6px;
}
div#DynamicsInteractivePanel > div.content > div.settings div.slider .control:active {
  border-color: black;
}
'''

onReady = (fn) ->
  loaded = document.readyState == "complete" || document.readyState == "loaded" || document.readyState == "interactive"
  if !loaded
    document.addEventListener "DOMContentLoaded", =>
      fn()
    , false
  else
    fn()

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

class UIGraph
  constructor: (canvas) ->
    @points = null
    @dynamic = null
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
    @canvas.addEventListener 'keyup', @canvasKeyUp
    @canvas.addEventListener 'keydown', (e) =>
      e.preventDefault()

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

    @dynamic.init()
    graphes = []
    colors = [ '#007EFF' ]
    defaultColor = '#D5E6F8'
    colorI = 0
    while args = @dynamic.next(step)
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
      e.stopPropagation()
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
    return unless @points
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

class UIPanel
  constructor: (@options = {}) ->
    @animations = []
    @currentAnimation = null
    @hidden = true

  show: (loaded = false) =>
    return unless @hidden
    if !loaded
      return onReady =>
        @show(true)

    @hidden = false

    @el = document.createElement('div')
    @el.id = 'DynamicsInteractivePanel'
    @el.addEventListener 'click', (e) ->
      e.stopPropagation()

    windowTitle = document.createElement('div')
    windowTitle.className = 'title'
    windowTitle.innerHTML = "Dynamics.js - Curve creator"
    @makeDraggable(windowTitle)
    @el.appendChild(windowTitle)

    contentEl = document.createElement('div')
    contentEl.className = 'content'

    graphEl = document.createElement('div')
    graphEl.className = 'graph'

    canvas = document.createElement('canvas')
    canvas.setAttribute('tabIndex', '0')
    canvas.width = "350"
    canvas.height = "350"

    spanIndex0 = document.createElement('span')
    spanIndex0.className = 'index0'
    spanIndex0.innerHTML = '0'

    spanIndex1 = document.createElement('span')
    spanIndex1.className = 'index1'
    spanIndex1.innerHTML = '1'

    graphEl.appendChild(canvas)
    graphEl.appendChild(spanIndex0)
    graphEl.appendChild(spanIndex1)
    contentEl.appendChild(graphEl)

    settingsEl = document.createElement('div')
    settingsEl.className = 'settings'

    @select = document.createElement('select')
    @select.className = 'dynamics'

    @optionsEl = document.createElement('div')
    @optionsEl.className = 'options'

    settingsEl.appendChild(@select)
    settingsEl.appendChild(@optionsEl)
    contentEl.appendChild(settingsEl)
    @el.appendChild(contentEl)

    @dynamicsClasses = []
    for k, v of Dynamics.Types
      @dynamicsClasses.push v

    @currentCircle = null
    @dynamicsClass = @dynamicsClasses[0]
    for aDynamicsClass in @dynamicsClasses
      if aDynamicsClass.name == @options.type
        @dynamicsClass = aDynamicsClass
      option = document.createElement('option')
      option.innerHTML = "Dynamics.Types.#{aDynamicsClass.name}"
      option.value = aDynamicsClass.name
      @select.appendChild option
    @select.addEventListener 'change', @selectDidChange
    @graph = new UIGraph(canvas)
    @sliders = []
    @properties = []

    document.body.appendChild(@el)

  refreshFromAnimation: =>
    return if @hidden
    @select.value = @currentAnimation.options.type.name
    @selectDidChange()

  selectDidChange: =>
    name = @select.options[@select.selectedIndex].value
    @dynamicsClass = eval("Dynamics.Types.#{name}")
    @updateOptions()
    @update()

  updateOptions: =>
    @optionsEl.innerHTML = ''
    values = @currentAnimation.options
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
        @optionsEl.appendChild(uiProperty.el)
        @properties.push(uiProperty)
      else
        slider = new UISlider({
          min: config.min,
          max: config.max,
          value: values[property] || config.default,
          property: property
        })
        @optionsEl.appendChild(slider.el)
        @sliders.push slider
    for slider in @sliders
      slider.onUpdate = @update

  update: =>
    return unless @currentAnimation
    options = {}
    for slider in @sliders
      options[slider.options.property] = slider.value()
    options['type'] = @dynamicsClass if @dynamicsClass
    options['points'] = @points if @points
    for k in ['complete', 'optionsChanged', 'debugName']
      options[k] = @currentAnimation.options[k]
    @options = options

    Overrides.setOverride(@options, @currentAnimation.options.debugName)
    @currentAnimation.setOptions(@options)

    @graph.dynamic = @currentAnimation.dynamic()
    @graph.points = @currentAnimation.dynamic().options.points
    @graph.pointsChanged = @update
    @graph.draw()

    for uiProperty in @properties
      uiProperty.setValue(@currentAnimation.dynamic()[uiProperty.options.property]())

    @onUpdate?()

  addAnimation: (animation) =>
    @show()
    @animations.push animation
    if !@currentAnimation
      @currentAnimation = animation
      @refreshFromAnimation()

  removeAnimation: (animation) =>
    pos = @animations.indexOf(animation)
    return if pos == -1
    @animations.splice(pos, 1)
    if animation == @currentAnimation
      if @animations.length > 0
        @currentAnimation = @animations[0]
      else
        @currentAnimation = null
      @refreshFromAnimation()

  makeDraggable: (el) =>
    initialPos = null
    initialTopLeft = null
    _windowMouseMove = (e) =>
      pos = { x: e.pageX, y: e.pageY }
      @el.style.top = (Math.max(0, initialTopLeft.top + pos.y - initialPos.y)) + 'px'
      @el.style.left = (initialTopLeft.left + pos.x - initialPos.x) + 'px'

    _windowMouseUp = (e) =>
      window.removeEventListener('mousemove', _windowMouseMove)
      window.removeEventListener('mouseup', _windowMouseUp)

    el.addEventListener 'mousedown', (e) =>
      initialPos = { x: e.pageX, y: e.pageY }
      style = window.getComputedStyle(@el)
      initialTopLeft = { top: parseInt(style.top, 10), left: parseInt(style.left, 10) }

      window.addEventListener('mousemove', _windowMouseMove)
      window.addEventListener('mouseup', _windowMouseUp)

Overrides =
  overrides: {}

  for: (name) =>
    return true

  getOverride: (options, name) =>
    return options unless Overrides.overrides[name]
    newOptions = {}
    for k, v of options
      newOptions[k] = v
    for k, v of Overrides.overrides[name]
      newOptions[k] = v if k != 'complete'
    newOptions

  setOverride: (options, name) =>
    newOptions = {}
    for k, v of options
      newOptions[k] = v
    Overrides.overrides[name] = newOptions

window.Dynamics = {} if !window.Dynamics
window.Dynamics.InteractivePanel = new UIPanel
window.Dynamics.Overrides = Overrides

onReady =>
  style = document.createElement('style')
  style.innerHTML = css
  document.head.appendChild(style)

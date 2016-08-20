roundf = (float, decimals) ->
  factor = Math.pow(10, decimals)
  Math.round(float * factor) / factor

merge = (a, b) ->
  c = {}
  for k, v of a
    c[k] = v
  for k, v of b
    c[k] = v
  c

class UIGraph
  constructor: (canvas) ->
    @points = null
    @curve = null
    @canvas = canvas
    @ctx = canvas.getContext('2d')
    @editable = false

    @r = window.devicePixelRatio || 1
    if @r
      canvas.style.width = "#{canvas.width}px"
      canvas.style.height = "#{canvas.height}px"
      canvas.width = canvas.width * @r
      canvas.height = canvas.height * @r

    @canvas.addEventListener 'mousedown', @canvasMouseDown
    @canvas.addEventListener 'mousemove', @canvasMouseMove
    @canvas.addEventListener 'mouseup', @canvasMouseUp
    @canvas.addEventListener 'keyup', @canvasKeyUp
    @canvas.addEventListener 'keydown', (e) =>
      e.preventDefault()

  draw: =>
    return unless @curve

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

    t = 0
    @ctx.beginPath()
    @ctx.strokeStyle = '#0070FF'
    @ctx.lineWidth = (2 * r)
    while t <= 1
      v = @curve(t)
      y = h - ((0.33 + (v * 0.33)) * h)
      if t == 0
        @ctx.moveTo(t * w, y)
      else
        @ctx.lineTo(t * w, y)
      t += step
    @ctx.stroke()

    if @points
      for point in @points
        # Draw line between point and each control points
        for controlPoint in point.cp
          @ctx.beginPath()
          @ctx.strokeStyle = 'blue'
          @ctx.lineWidth = 1
          coords = @pointCoordinates(point)
          @ctx.moveTo(coords.x, coords.y)
          coordsControlPoint = @pointCoordinates(controlPoint)
          @ctx.lineTo(coordsControlPoint.x, coordsControlPoint.y)
          @ctx.stroke()

      for point in @points
        # Draw point
        @ctx.beginPath()
        @ctx.strokeStyle = if @selectedPoint == point then 'black' else 'blue'
        @ctx.fillStyle = 'white'
        @ctx.lineWidth = 2 * r
        coords = @pointCoordinates(point)
        @ctx.arc(coords.x, coords.y, 5 * r, 0, Math.PI*2, true)
        @ctx.fill()
        @ctx.stroke()

        # Draw control points
        for controlPoint in point.cp
          @ctx.beginPath()
          @ctx.strokeStyle = if @selectedPoint == controlPoint then 'black' else 'blue'
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
    return null if !@points? or @points.length < 2
    for point in @points
      if point != @points[0]
        return point if @isLocationAroundCenter(location, @pointCoordinates(point), 14)
      for controlPoint in point.cp
        return controlPoint if @isLocationAroundCenter(location, @pointCoordinates(controlPoint), 10)
    null

  canvasMouseDown: (e) =>
    return unless @editable
    location = @locationFromEvent(e)
    @selectedPoint = @pointFromLocation(location)
    unless @selectedPoint
      converted = @convertFromCoordinates(location)
      @selectedPoint = {
        x: converted.x,
        y: converted.y,
        cp: [
          { x: converted.x - 0.1, y: converted.y },
          { x: converted.x + 0.1, y: converted.y }
        ]
      }
      @insertPoint(@selectedPoint)
    @pointsChanged?()
    @draw()
    @dragging = true

  canvasMouseMove: (e) =>
    return unless @editable
    return unless @selectedPoint
    return unless @dragging
    location = @locationFromEvent(e)
    point = @convertFromCoordinates(location)
    if @selectedPoint == @points[@points.length - 1]
      point.x = 1
      point.y = Math.min(1, Math.max(0, Math.round(point.y)))
    if @selectedPoint.cp
      for controlPoint in @selectedPoint.cp
        controlPoint.x = roundf(controlPoint.x + point.x - @selectedPoint.x, 3)
        controlPoint.y = roundf(controlPoint.y + point.y - @selectedPoint.y, 3)
    @selectedPoint.x = point.x
    @selectedPoint.y = point.y
    @pointsChanged?()
    @draw()

  canvasMouseUp: (e) =>
    return unless @editable
    @dragging = false
    @pointsChanged?()

  canvasKeyUp: (e) =>
    return unless @editable
    return unless @selectedPoint
    if e.keyCode == 8
      # Cannot delete control points
      return unless @selectedPoint.cp
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
    @options.min ?= 0
    @options.max ?= 1000
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

    @slider.addEventListener('mousedown', @_sliderMouseDown)
    @control.addEventListener('mousedown', @_controlMouseDown)

  value: =>
    @options.value

  _updateLeftFromValue: =>
    @control.style.left = (@options.value - @options.min) / (@options.max - @options.min) * @width + "px"

  _sliderMouseDown: (e) =>
    layerX = e.layerX

    @options.value = Math.round(layerX / (@width + 11) * (@options.max - @options.min) + @options.min)
    @valueEl.innerHTML = @options.value

    @onUpdate?()

    @control.style.left = Math.round(layerX / (@width + 11) * @width) + "px"

    @_controlMouseDown(e)

  _controlMouseDown: (e) =>
    @dragging = true
    @startPoint = [e.pageX, e.pageY]
    @startLeft = parseInt(@control.style.left || 0)
    @control.classList.add('highlighted')
    window.addEventListener('mousemove', @_windowMouseMove)
    window.addEventListener('mouseup', @_windowMouseUp)
    e.stopPropagation()

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
    @control.classList.remove('highlighted')
    window.removeEventListener('mousemove', @_windowMouseMove)
    window.removeEventListener('mouseup', @_windowMouseUp)

class Editor
  constructor: (@options = {}) ->
    @width = 580
    @height = (@width - 234)
    @duration = 1000

    @el = document.createElement('div')
    @el.id = 'editor'
    @el.addEventListener 'click', (e) ->
      e.stopPropagation()

    graphEl = document.createElement('div')
    graphEl.className = 'graph'

    @canvas = document.createElement('canvas')
    @canvas.setAttribute('tabIndex', '0')
    r = window.devicePixelRatio || 1
    canvasSize = (@width - 234)
    @canvas.width = "#{canvasSize}"
    @canvas.height = "#{canvasSize}"

    spanIndex0 = document.createElement('span')
    spanIndex0.className = 'index0'
    spanIndex0.innerHTML = '0'

    spanIndex1 = document.createElement('span')
    spanIndex1.className = 'index1'
    spanIndex1.innerHTML = '1'

    graphEl.appendChild(@canvas)
    graphEl.appendChild(spanIndex0)
    graphEl.appendChild(spanIndex1)
    @el.appendChild(graphEl)

    settingsEl = document.createElement('div')
    settingsEl.className = 'settings'

    @select = document.createElement('select')
    @select.className = 'dynamics'

    @optionsEl = document.createElement('div')
    @optionsEl.className = 'options'

    settingsEl.appendChild(@select)
    settingsEl.appendChild(@optionsEl)
    @el.appendChild(settingsEl)

    @currentCircle = null
    @select.addEventListener 'change', @selectDidChange
    @graph = new UIGraph(@canvas)
    @graph.pointsChanged = @onPointsChanged
    @sliders = []
    @properties = []

    @el.style.width = @width + 'px'
    @el.style.height = @height + 'px'

    @fillSelect()
    @selectDidChange()

  fillSelect: =>
    sortedDynamicsKeys = [
      'spring', 'bounce', 'forceWithGravity', 'gravity', 'bezier', 'easeInOut', 'easeIn', 'easeOut', 'linear'
    ]
    for k in sortedDynamicsKeys
      option = document.createElement('option')
      option.innerHTML = "dynamics.#{k}"
      option.value = k
      @select.appendChild(option)

  selectDidChange: =>
    @select.blur()
    name = @select.options[@select.selectedIndex].value
    if name == "bezier"
      @graph.points = [
        { x:0, y:0, cp:[ {x:0.1, y:0}] },
        { x:1, y:1, cp:[ {x:0.9, y:1}] },
      ]
      @graph.editable = true
    else
      @graph.points = null
      @graph.editable = false
    @curveName = "dynamics.#{name}"
    @curve = eval(@curveName)
    @values = {}
    for k, v of @curve.defaults
      @values[k] = v
    @fillSettings()
    @update()

  fillSettings: =>
    @optionsEl.innerHTML = ''
    @sliders = []

    slider = new UISlider({
      min: 100,
      max: 5000,
      value: @duration,
      property: "duration"
    })
    slider.onUpdate = @update
    @optionsEl.appendChild(slider.el)
    @sliders.push(slider)

    for k, v of @curve.defaults
      slider = new UISlider({
        min: if v == 0 then 0 else 1,
        max: 1000,
        value: @values[k],
        property: k
      })
      slider.onUpdate = @update
      @optionsEl.appendChild(slider.el)
      @sliders.push(slider)

  update: =>
    for slider in @sliders
      if slider.options.property == 'duration'
        @duration = slider.value()
      else
        @values[slider.options.property] = slider.value()

    if @graph.points?
      points = @graph.points.slice()
      points = points.sort (a, b) ->
        return -1 if a.x < b.x
        1
      @values.points = points
    else
      delete @values.points

    @redraw()
    @options.onChange?.call(@)
    @startAnimationDelayed()

  redraw: =>
    @graph.curve = @curve(@values)
    @graph.draw()

  onPointsChanged: =>
    @update()

  code: (html=false) =>
    strong1 = if html then "<strong>" else ""
    strong2 = if html then "</strong>" else ""
    props = ""
    if @duration != 1000
      props += ",\n  #{strong1}duration#{strong2}: #{@duration}"
    for k, v of @values
      if k == "points"
        v = JSON.stringify(v)
      if v != @curve?.defaults?[k]
        props += ",\n  #{strong1}#{k}#{strong2}: #{v}"
    """#{strong1}dynamics.animate#{strong2}(document.querySelector('.circle'), {
      #{strong1}translateX#{strong2}: 350
    }, {
      #{strong1}type#{strong2}: #{@curveName}#{props}
    })"""

  startAnimationDelayed: =>
    dynamics.clearTimeout(@delayedAnimation)
    @delayedAnimation = dynamics.setTimeout(@startAnimation, 100)

  startAnimation: =>
    timeout = 0
    if @circle?
      oldCircle = @circle
      @circle = null
      dynamics.animate(oldCircle, {
        opacity: 0
      }, {
        type: dynamics.easeInOut,
        duration: 100,
        complete: =>
          demo = document.querySelector('.demo')
          demo.removeChild(oldCircle) if oldCircle.parentNode?
      })

    @circle = circle = @createCircle()
    clearTimeout(@restartAnimationTimeout)

    initialForce = @curve(@values).initialForce

    options = merge(@values, {
      type: @curve,
      duration: @duration,
      delay: 250,
      complete: =>
        wasCircle = @circle
        return if @circle != circle
        @circle = null
        @restartAnimationTimeout = dynamics.setTimeout(@startAnimation, 300)
        dynamics.animate(circle, {
          translateX: if initialForce then 0 else 350,
          scale: 0.01
        }, {
          type: dynamics.easeInOut,
          duration: 100,
          delay: 100,
          complete: =>
            demo = document.querySelector('.demo')
            demo.removeChild(circle) if circle.parentNode?
        })
    })

    dynamics.animate(circle, {
      translateX: 350
    }, options)

  createCircle: =>
    demo = document.querySelector('.demo')
    circle = document.createElement('div')
    circle.className = 'circle'
    dynamics.css(circle, {
      scale: 0.01
    })
    demo.appendChild(circle)
    dynamics.animate(circle, {
      scale: 1
    }, {
      type: dynamics.spring,
      friction: 300,
      duration: 800
    })
    circle

dynamics.Editor = Editor

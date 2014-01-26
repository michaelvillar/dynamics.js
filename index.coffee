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
    @canvas = canvas
    @ctx = canvas.getContext('2d')

    @r = window.devicePixelRatio || 1
    if @r
      canvas.width = canvas.width * @r
      canvas.height = canvas.height * @r
      canvas.style[BrowserSupport.prefixFor('transform-origin') + 'TransformOrigin'] = "0 0"
      canvas.style[BrowserSupport.prefixFor('transform') + 'Transform'] = 'scale('+(1 / @r)+')'

  draw: =>
    r = window.devicePixelRatio
    w = @canvas.width
    h = @canvas.height

    step = 0.001

    @ctx.clearRect(0,0,w,h)

    @ctx.strokeStyle = 'gray'
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
    while args = @tween.next(step)
      for i in [1..args.length]
        graphes[i - 1] ||= []
        points = graphes[i - 1]
        points.push [args[0], args[i]]
      if args[0] >= 1
        break

    colors = [ 'red', 'rgba(0, 0, 255, .3)', 'rgba(0, 255, 0, .3)', 'rgba(0, 255, 255, .3)', 'rgba(255, 255, 0, .3)']
    defaultColor = 'rgba(0, 0, 0, .3)'

    colorI = 0
    for points in graphes
      color = defaultColor
      color = colors[colorI] if colorI < colors.length
      @ctx.beginPath()
      @ctx.strokeStyle = color
      @_drawCurve(points)
      if colorI == 0
        @ctx.lineWidth = (2 * r)
      else
        @ctx.lineWidth = (1 * r)
      @ctx.stroke()
      colorI += 1

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

    @width = 200 - 10

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
        values[k] = v
    values

  @saveValues: (args) =>
    argsString = ''
    for k, v of args
      argsString += "," unless argsString == ''
      argsString += "#{k}=#{v}"

    currentURL = (document.location.toString() || '').split('#')[0]
    document.location = currentURL + "#" + argsString

class App
  dynamicsClasses: [Dynamics.Spring, Dynamics.SelfSpring, Dynamics.Gravity, Dynamics.GravityWithForce]

  constructor: ->
    @animateToRight = true
    @select = document.querySelector('select.dynamics')
    @dynamicsClass = @dynamicsClasses[0]
    for aDynamicsClass in @dynamicsClasses
      if aDynamicsClass.name == Tools.valuesFromURL().dynamic
        @dynamicsClass = aDynamicsClass
      option = document.createElement('option')
      option.innerHTML = "Dynamics.#{aDynamicsClass.name}"
      option.value = aDynamicsClass.name
      option.selected = aDynamicsClass == @dynamicsClass
      @select.appendChild option
    @select.addEventListener 'change', @selectDidChange
    @graph = new Graph(document.querySelector('canvas'))
    @sliders = []
    @properties = []

    document.querySelector('div.circle').addEventListener 'click', @animate

    @updateOptions()
    @update()

  selectDidChange: =>
    name = @select.options[@select.selectedIndex].value
    @dynamicsClass = eval("Dynamics.#{name}")
    @updateOptions()
    @update()

  updateOptions: =>
    tweenOptionsEl = document.querySelector('.options')
    tweenOptionsEl.innerHTML = ''
    values = Tools.valuesFromURL()
    @sliders = []
    @properties = []
    for property, config of @dynamicsClass.properties
      if config.editable == false
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
    Tools.saveValues(args)
    clearTimeout @animationTimeout if @animationTimeout
    @animationTimeout = setTimeout(@animate, 400)

    @createDynamic()

    @graph.tween = @dynamic.tween()
    @graph.draw()

    for uiProperty in @properties
      uiProperty.setValue(@dynamic.tween()[uiProperty.options.property]())

  createDynamic: =>
    options = { }
    for slider in @sliders
      options[slider.options.property] = slider.value()
    if @dynamicsClass != Dynamics.SelfSpring
      from = { translateX: if @animateToRight then 0 else 350 }
      to = { translateX: if !@animateToRight then 0 else 350 }
    else
      from = { translateX: if @animateToRight then 0 else 350 }
      to = { translateX: if @animateToRight then 50 else 300 }
    @dynamic = new @dynamicsClass(document.querySelector('div.circle'), from, to, options)

  animate: =>
    @createDynamic()
    @dynamic.start()
    if !@dynamicsClass.returnsToSelf
      @animateToRight = !@animateToRight

document.addEventListener "DOMContentLoaded", ->
  app = new App
, false
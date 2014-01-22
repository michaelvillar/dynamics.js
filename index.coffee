class TweenSpring
  @properties:
    frequency: { min: 0, max: 100, default: 15 }
    friction: { min: 1, max: 1000, default: 100 }
    anticipationStrength: { min: 0, max: 1000, default: 115 }
    anticipationSize: { min: 0, max: 99, default: 10 }

  constructor: (@options = {}) ->

  init: =>
    @t = 0
    @speed = 0
    @v = 0

  next: (step) =>
    @t = 1 if @t > 1
    t = @t
    @t += step

    frequency = Math.max(1, @options.frequency)
    friction = Math.pow(20, (@options.friction / 100))
    s = @options.anticipationSize / 100
    decal = Math.max(0, s)

    frictionT = (t / (1 - s)) - (s / (1 - s))

    if t < s
      # In case of anticipation
      A = (t) =>
        M = 0.8

        x0 = (s / (1 - s))
        x1 = 0

        b = (x0 - (M * x1)) / (x0 - x1)
        a = (M - b) / x0

        (a * t * @options.anticipationStrength / 100) + b

      yS = (s / (1 - s)) - (s / (1 - s))
      y0 = (0 / (1 - s)) - (s / (1 - s))
      b = Math.acos(1 / A(yS))
      a = (Math.acos(1 / A(y0)) - b) / (frequency * (-s))
    else
      # Normal curve
      A = (t) =>
        Math.pow(friction / 10,-t) * (1 - t)

      b = 0
      a = 1

    At = A(frictionT)

    angle = frequency * (t - s) * a + b
    v = 1 - (At * Math.cos(angle))
    [t, v, At, frictionT, angle]

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

class Animation
  @index: 0

  constructor: (@el, @frames = {}, @options = {}) ->
    @options.tween ||= TweenLinear
    @options.duration ||= 1000

  start: =>
    name = "anim_#{Animation.index}"
    Animation.index += 1
    keyframes = @_keyframes(name)
    style = document.createElement('style')
    style.innerHTML = keyframes
    document.head.appendChild(style)

    animation = {
      name: name,
      duration: @options.duration + 'ms',
      timingFunction: 'linear',
      fillMode: 'forwards'
    }
    for k, v of animation
      property = "animation-#{k}"
      prefix = BrowserSupport.prefixFor(property)
      propertyName = prefix + "Animation" + k.substring(0, 1).toUpperCase() + k.substring(1)
      @el.style[propertyName] = v

  # Private
  _keyframes: (name) =>
    @options.tween.init()
    step = 0.01

    # percents = []
    # for percent in @frames
    #   percents.push percent / 100
    # percents = percents.sort()

    frame0 = @frames[0]
    frame1 = @frames[100]

    css = "@#{BrowserSupport.keyframes()} #{name} {\n"
    while args = @options.tween.next(step)
      [t, v] = args

      transform = ''
      properties = {}
      for k, value of frame1
        value = parseFloat(value)
        oldValue = frame0[k] || 0
        dValue = value - oldValue
        newValue = oldValue + (dValue * v)

        unit = ''
        isTransform = false
        if k in ['translateX', 'translateY', 'translateZ']
          unit = 'px'
          isTransform = true
        else if k in ['rotateX', 'rotateY', 'rotateZ']
          unit = 'deg'
          isTransform = true
        else if k in ['scaleX', 'scaleY', 'scale']
          isTransform = true

        if isTransform
          transform += "#{k}(#{newValue}#{unit}) "
        else
          properties[k] = newValue

      css += "#{(t * 100)}% {\n"
      css += "#{BrowserSupport.transform()}: #{transform};\n" if transform
      for k, v of properties
        css += "#{k}: #{v};\n"
      css += " }\n"

      if t >= 1
        break
    css += "}\n"
    css

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

class UISlider
  constructor: (@el, @valueEl, @options = {}) ->
    @options.min ||= 0
    @options.max ||= 1000
    @options.value = 10 if @options.value == undefined

    @width = 200 - 10

    @bar = document.createElement('div')
    @bar.classList.add('bar')
    @control = document.createElement('div')
    @control.classList.add('control')
    @el.appendChild(@bar)
    @el.appendChild(@control)
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

document.addEventListener "DOMContentLoaded", ->
  graph = new Graph(document.querySelector('canvas'))
  tweenClass = TweenSpring

  url = (document.location.toString() || '').split('#')
  values = {}
  if url.length > 1
    query = url[1]
    for arg in query.split(',')
      [k, v] = arg.split('=')
      values[k] = v

  @duration = new UISlider(document.querySelector('.slider.duration'), document.querySelector('.value.duration'), {
    start: 100,
    end: 4000,
    value: values.duration || 1000
  })

  sliders = []
  for property, config of tweenClass.properties
    slider = new UISlider(document.querySelector('.slider.' + property), document.querySelector('.value.' + property), {
      min: config.min,
      max: config.max,
      value: values[property] || config.default,
      property: property
    })
    sliders.push slider

  animationTimeout = null

  tween = =>
    options = {}
    for slider in sliders
      options[slider.options.property] = slider.value()
    new TweenSpring(options)

  animateToRight = true
  animate = =>
    anim = new Animation(document.querySelector('div.circle'), {
      0: {
        translateX: if animateToRight then 0 else 350
      },
      100: {
        translateX: if animateToRight then 350 else 0
      }
    }, {
      tween: tween(),
      duration: @duration.value()
    })
    animateToRight = !animateToRight
    anim.start()

  update = =>
    args = {}
    for slider in sliders
      args[slider.options.property] = slider.value()
    argsString = ''
    for k, v of args
      argsString += "," unless argsString == ''
      argsString += "#{k}=#{v}"

    currentURL = (document.location.toString() || '').split('#')[0]
    document.location = currentURL + "#" + argsString

    graph.tween = tween()
    graph.draw()

    clearTimeout animationTimeout if animationTimeout
    animationTimeout = setTimeout(animate, 200)

  @duration.onUpdate = update
  for slider in sliders
    slider.onUpdate = update
  update()

  document.querySelector('div.circle').addEventListener 'click', animate

, false
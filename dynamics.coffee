class Tween
  @properties: {}

  constructor: (@options = {}) ->

  init: =>
    @t = 0

  next: (step) =>
    @t = 1 if @t > 1
    @currentT = @t
    @t += step

class TweenLinear extends Tween
  init: =>
    super

  next: (step) =>
    super step
    t = @currentT
    [t, t]

class TweenForce extends Tween
  init: =>
    super

  next: (step) =>
    super step
    t = @currentT

    gravity = 1
    v = 2 * t - gravity * t * t

    [t, v]

class TweenGravity extends Tween
  @properties:
    bounce: { min: 0, max: 80, default: 40 }
    gravity: { min: 1, max: 4000, default: 1000 }
    duration: { editable: false }

  duration: =>
    Math.round(1000 * 1000 / @options.gravity * @length())

  bounceValue: =>
    bounce = (@options.bounce / 100)
    bounce = Math.min(bounce, 80)
    bounce

  gravityValue: =>
    @options.gravity / 100

  length: =>
    bounce = @bounceValue()
    gravity = @gravityValue()
    b = Math.sqrt(2 / gravity)
    curve = { a: -b, b: b, H: 1 }
    curve.a = 0 if @options.initialForce
    while curve.H > 0.001
      L = curve.b - curve.a
      curve = { a: curve.b, b: curve.b + L * bounce, H: curve.H * bounce * bounce }
    curve.b

  init: =>
    super
    L = @length()
    gravity = @gravityValue()
    gravity = gravity * L * L
    bounce = @bounceValue()

    b = Math.sqrt(2 / gravity)
    @curves = []
    curve = { a: -b, b: b, H: 1 }
    curve.a = 0 if @options.initialForce
    @curves.push curve
    while curve.b < 1 and curve.H > 0.001
      L = curve.b - curve.a
      curve = { a: curve.b, b: curve.b + L * bounce, H: curve.H * bounce * bounce }
      @curves.push curve

  curve: (a, b, H, t) =>
    L = b - a
    t2 = (2 / L) * (t) - 1 - (a * 2 / L)
    c = t2 * t2 * H - H + 1
    c = 1 - c if @options.initialForce
    c

  next: (step) =>
    super step
    t = @currentT
    bounce = (@options.bounce / 100)
    gravity = @options.gravity

    i = 0
    curve = @curves[i]
    while(!(t >= curve.a and t <= curve.b))
      i += 1
      curve = @curves[i]
      break unless curve

    if !curve
      if @options.initialForce
        v = 0
      else
        v = 1
    else
      v = @curve(curve.a, curve.b, curve.H, t)

    [t, v]

class TweenSpring extends Tween
  @properties:
    frequency: { min: 0, max: 100, default: 15 }
    friction: { min: 1, max: 1000, default: 100 }
    anticipationStrength: { min: 0, max: 1000, default: 115 }
    anticipationSize: { min: 0, max: 99, default: 10 }
    duration: { min: 100, max: 4000, default: 1000 }

  next: (step) =>
    super step
    t = @currentT

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

class TweenSpring2 extends Tween
  @properties:
    frequency: { min: 0, max: 100, default: 15 }
    friction: { min: 1, max: 1000, default: 100 }
    duration: { min: 100, max: 4000, default: 1000 }

  next: (step) =>
    super step
    t = @currentT

    frequency = Math.max(1, @options.frequency)
    friction = Math.pow(20, (@options.friction / 100))

    # Normal curve
    A = (t) =>
      1 - Math.pow(friction / 10,-t) * (1 - t)

    At = A(t)
    At2 = A(1-t)

    Ax = (Math.cos(t * 2 * 3.14 - 3.14) / 2) + 0.5
    Ax = Math.pow(Ax, @options.friction / 100)

    angle = frequency * t
    # v = 1 - (At * Math.cos(angle))
    v = Math.cos(angle) * Ax
    [t, v, Ax, -Ax]

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

class Dynamic
  @index: 0
  @returnsToSelf: false
  tweenClass: "TweenLinear"

  constructor: (@el, @frames = {}, @options = {}) ->
    @options.duration ||= 1000

  tween: =>
    @_tween ||= eval("new #{@tweenClass}(this.options)")
    @_tween

  start: =>
    name = "anim_#{Dynamic.index}"
    Dynamic.index += 1
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
    @tween().init()
    step = 0.01

    frame0 = @frames[0]
    frame1 = @frames[100]

    css = "@#{BrowserSupport.keyframes()} #{name} {\n"
    while args = @tween().next(step)
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

class Spring extends Dynamic
  tweenClass: "TweenSpring"
  @properties: TweenSpring.properties

  constructor: (@el, @from, @to, @options = {}) ->
    @frames = {
      0: @from,
      100: @to
    }
    super @el, @frames, @options

class SelfSpring extends Dynamic
  tweenClass: "TweenSpring2"
  @properties: TweenSpring2.properties
  @returnsToSelf: true

  constructor: (@el, @from, @to, @options = {}) ->
    @frames = {
      0: @from,
      100: @to
    }
    super @el, @frames, @options

class Gravity extends Dynamic
  tweenClass: "TweenGravity"
  @properties: TweenGravity.properties

  constructor: (@el, @from, @to, @options = {}) ->
    @frames = {
      0: @from,
      100: @to
    }
    @options.duration = @tween().duration()
    super @el, @frames, @options

class GravityWithForce extends Dynamic
  tweenClass: "TweenGravity"
  @properties: TweenGravity.properties
  @returnsToSelf: true

  constructor: (@el, @from, @to, @options = {}) ->
    @frames = {
      0: @from,
      100: @to
    }
    @options.duration = @tween().duration()
    @options.initialForce = true
    super @el, @frames, @options

@Dynamics =
  Spring: Spring
  SelfSpring: SelfSpring
  Gravity: Gravity
  GravityWithForce: GravityWithForce
  BrowserSupport: BrowserSupport
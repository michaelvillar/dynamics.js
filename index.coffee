TweenLinear =
  init: =>
    @t = 0
  next: (step) =>
    @t = 1 if @t > 1
    t = @t
    v = @t
    @t += step
    [t, v]

class TweenSpring
  constructor: (@frequency, @friction, @anticipation) ->

  init: =>
    @t = 0
    @speed = 0
    @v = 0

  next: (step) =>
    @t = 1 if @t > 1
    t = @t
    @t += step

    A = (t) =>
      Math.pow(@friction / 10,-t) * (1 - t)

    v = A(t) * Math.cos(@frequency * t)
    v = 1 - v


    tAt0 = 1 / (@frequency / 3.14)
    # -3 = -tAt0 * friction / 100
    # -300 = -tAt0 * friction
    friction = 300 / tAt0

    startA = (t) =>
      Math.pow(10,-t * friction / 100)

    v2 = v
    # v3 = (startA(t) * Math.sin(@startFrequency * t))
    v3 = - @anticipation * t * startA(t)
    v = v + v3

    [t, v, v2, v3]

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

    @el.style.webkitAnimationName = name
    @el.style.webkitAnimationDuration = @options.duration + 'ms'
    @el.style.webkitAnimationTimingFunction = 'linear'
    @el.style.webkitAnimationFillMode = 'forwards'

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

    css = "@-webkit-keyframes #{name} {\n"
    while args = @options.tween.next(step)
      [t, v] = args

      transform = ''
      for k, value of frame1
        if k == 'translateX'
          value = parseInt(value)
          oldValue = frame0.translateX || 0
          dValue = value - oldValue
          transform += "translateX(#{oldValue + (dValue * v)}px) "

      css += "#{(t * 100)}% { "
      css += "-webkit-transform: #{transform};" if transform
      css += " }"

      if t >= 1
        break
    css += "}"
    css

class Graph
  constructor: (canvas) ->
    @canvas = canvas
    @ctx = canvas.getContext('2d')

    @r = window.devicePixelRatio || 1
    if @r
      canvas.width = canvas.width * @r
      canvas.height = canvas.height * @r
      canvas.style.webkitTransformOrigin = "0 0"
      canvas.style.webkitTransform = 'scale('+(1 / @r)+')'

  draw: =>
    r = window.devicePixelRatio
    w = @canvas.width
    h = @canvas.height

    step = 0.001

    @ctx.clearRect(0,0,w,h)

    @ctx.setStrokeColor('gray')
    @ctx.setLineWidth(1)
    @ctx.beginPath()
    @ctx.moveTo(0, 0.67 * h)
    @ctx.lineTo(w, 0.67 * h)
    @ctx.stroke()

    @ctx.beginPath()
    @ctx.moveTo(0, 0.34 * h)
    @ctx.lineTo(w, 0.34 * h)
    @ctx.stroke()

    @tween.init()
    points = []
    points2 = []
    points3 = []
    while args = @tween.next(step)
      [t, v, v2, v3] = args
      points.push [t, v]
      points2.push [t, v2]
      points3.push [t, v3]
      if t >= 1
        break

    @ctx.beginPath()
    @ctx.setStrokeColor('red')
    @_drawCurve(points)
    @ctx.setLineWidth(2 * r)
    @ctx.stroke()

    @ctx.beginPath()
    @ctx.setStrokeColor('rgba(0, 0, 255, .3)')
    @_drawCurve(points2)
    @ctx.setLineWidth(1 * r)
    @ctx.stroke()

    @ctx.beginPath()
    @ctx.setStrokeColor('rgba(0, 255, 0, .3)')
    @_drawCurve(points3)
    @ctx.setLineWidth(1 * r)
    @ctx.stroke()

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
    @options.start ||= 0
    @options.end ||= 1000
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
    @control.style.left = (@options.value - @options.start) / (@options.end - @options.start) * @width + "px"

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

    @options.value = Math.round(newLeft / @width * (@options.end - @options.start) + @options.start)
    @valueEl.innerHTML = @options.value

    @onUpdate?()

    @control.style.left = newLeft + "px"

  _windowMouseUp: (e) =>
    @dragging = false
    window.removeEventListener('mousemove', @_windowMouseMove)
    window.removeEventListener('mouseup', @_windowMouseUp)

document.addEventListener "DOMContentLoaded", ->
  graph = new Graph(document.querySelector('canvas'))

  @frequency = new UISlider(document.querySelector('.slider.frequency'), document.querySelector('.value.frequency'), {
    end: 100,
    value: 17
  })
  @friction = new UISlider(document.querySelector('.slider.friction'), document.querySelector('.value.friction'), {
    start: 1,
    end: 3000,
    value: 400
  })
  @anticipation = new UISlider(document.querySelector('.slider.anticipation'), document.querySelector('.value.anticipation'), {
    start: 0,
    end: 100,
    value: 0
  })
  @duration = new UISlider(document.querySelector('.slider.duration'), document.querySelector('.value.duration'), {
    start: 100,
    end: 10000,
    value: 1000
  })

  animationTimeout = null

  tween = =>
    new TweenSpring(@frequency.value(), @friction.value(), @anticipation.value())

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
    graph.tween = tween()
    graph.draw()

    clearTimeout animationTimeout if animationTimeout
    animationTimeout = setTimeout(animate, 200)

  update()
  @frequency.onUpdate = update
  @friction.onUpdate = update
  @anticipation.onUpdate = update
  @duration.onUpdate = update

  document.querySelector('div.circle').addEventListener 'click', animate

, false
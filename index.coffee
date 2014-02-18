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
    @firstCircle = true
    @track = document.querySelector('div.track')
    @codeSection = document.querySelector('section.code')
    @panel = new Panel(Tools.valuesFromURL())
    @panel.onUpdate = @update
    @update()

  update: =>
    # Update code
    @codeSection.innerHTML = @code()

    # Update URL
    options = {}
    for k, v of @panel.options
      continue if k == 'complete'
      if k == 'type'
        options[k] = v.name
      else
        options[k] = v
    Tools.saveValues(options)

    # Animate
    clearTimeout @animationTimeout if @animationTimeout
    @animationTimeout = setTimeout(@animate, 400)

  animate: =>
    @createDynamic()
    @dynamic.start()
    if !@dynamic.returnsToSelf
      @currentCircle = null

  createDynamic: =>
    options = @panel.options
    if options.type != Dynamics.Types.SelfSpring
      to = { transform: 'translateX(350px)' }
    else
      to = { transform: 'translateX(50px)' }
    @createCircle()
    circle = @currentCircle
    @dynamic = dynamic = new Dynamics.Animation(circle, to, options)
    shouldDeleteCircle = !dynamic.returnsToSelf
    options.complete = =>
      return unless shouldDeleteCircle
      @createDynamic()
      new Dynamics.Animation(circle, {
        transform: if !dynamic.returnsToSelf then 'translateX(350px) scale(0)' else 'translateX(0px) scale(0)',
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
    if options.type != Dynamics.Types.SelfSpring
      @track.classList.remove('tiny')
    else
      @track.classList.add('tiny')

  createCircle: =>
    return if @currentCircle
    @currentCircle = document.createElement('div')
    @currentCircle.classList.add('circle')
    @currentCircle.addEventListener 'click', =>
      @animate()
    unless @firstCircle
      @currentCircle.style['-webkit-transform'] = 'scale(0)'
      @currentCircle.style['transform'] = 'scale(0)'
      new Dynamics.Animation(@currentCircle, {
        transform: 'scale(1)'
      }, {
        type: Dynamics.Types.Spring,
        frequency: 0,
        friction: 600,
        anticipationStrength: 100,
        anticipationSize: 10,
        duration: 1000
      }).start()
    @firstCircle = false
    document.querySelector('section.demo').appendChild(@currentCircle)

  code: =>
    options = @panel.options
    translateX = if options.type != Dynamics.Types.SelfSpring then 350 else 50
    optionsStr = "&nbsp;&nbsp;<strong>type</strong>: Dynamics.Types.#{options.type.name}"
    for k, v of options
      continue if k == 'type' or k == 'complete'
      optionsStr += ",\n" if optionsStr != ''
      optionsStr += "&nbsp;&nbsp;<strong>#{k}</strong>: #{v}"
    if options.points
      pointsValue = JSON.stringify(options.points)
      optionsStr += ",\n&nbsp;&nbsp;<strong>points</strong>: #{pointsValue}"
    code = '''new <strong>Dynamics.Animation</strong>(document.getElementId("circle"), {
&nbsp;&nbsp;<strong>transform</strong>: "translateX(''' + translateX + '''px)"
}, {

''' + optionsStr + '''

}).start();'''
    code

document.addEventListener "DOMContentLoaded", ->
  app = new App
, false

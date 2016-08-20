SOCKS_COUNT = 34

fade = (->
  el = document.querySelector('#fade')
  el.style.display = 'none'

  hideTimeout = null
  hidden = true

  show = ->
    hidden = false
    el.style.display = 'block'
    clearTimeout(hideTimeout) if hideTimeout
    hideTimeout = null
    setTimeout =>
      el.className = 'visible'

  hide = ->
    hidden = true
    el.className = ''
    hideTimeout = setTimeout ->
      el.style.display = 'none'
    , 450

  {
    show: show,
    hide: hide,
    isHidden: ->
      hidden
  }
)()

cumulativeOffset = (el) ->
  top = 0
  left = 0
  while el
    top += el.offsetTop || 0
    left += el.offsetLeft || 0
    el = el.offsetParent

  {
    top: top,
    left: left
  }

logo = (->
  el = document.querySelector('#logo')
  el.addEventListener 'click', ->
    grid.closeCurrentItem()
    cart.close()

  scrollFade = 30

  updateOffset = (options = {}) ->
    options.animated ?= false
    return unless fade.isHidden()
    scrollY = Math.min(window.scrollY, scrollFade)
    offset = scrollY / scrollFade
    dynamics.animate(el, {
      opacity: 1 - offset,
      translateY: - offset * 10
    }, {
      type: dynamics.easeInOut,
      duration: 300,
      animated: options.animated
    })
    if offset >= 1
      el.className = "hidden"
    else
      el.className = ""

  show = ->
    dynamics.animate(el, {
      opacity: 1,
      translateY: 0
    }, {
      type: dynamics.spring,
      duration: 500
    })
    el.className = ""

  {
    show: show,
    updateOffset: updateOffset
  }
)()

product = (->
  el = document.querySelector('#product')
  texts = el.querySelectorAll('h2 > span, p > span, button')
  closeButtonEl = el.querySelector('a.close')
  closeButtonSpan = closeButtonEl.querySelector('span')
  closeButtonSpanVisible = false
  button = el.querySelector('button')

  closeButtonSpanStates = [
    { translateY: -58 },
    { translateX: -48, rotateZ: -90 }
  ]

  dynamics.css(closeButtonSpan, closeButtonSpanStates[1])

  closeButtonEl.addEventListener 'mouseover', =>
    closeButtonSpanVisible = true
    dynamics.animate(closeButtonSpan, {
      translateX: 0,
      translateY: 0,
      rotate: 0
    }, {
      type: dynamics.spring,
      frequency: 200,
      friction: 800,
      duration: 2000
    })

  hideCloseButton = (properties = null, options = null) ->
    return unless closeButtonSpanVisible
    closeButtonSpanVisible = false
    old = closeButtonSpan
    if properties?
      options.complete = ->
        old.parentNode.removeChild(old)
      dynamics.animate(old, properties, options)
    else
      old.parentNode.removeChild(old)

    closeButtonSpan = closeButtonSpan.cloneNode()
    dynamics.css(closeButtonSpan, closeButtonSpanStates[1])
    closeButtonEl.appendChild(closeButtonSpan)

  closeButtonEl.addEventListener 'mouseout', =>
    hideCloseButton(closeButtonSpanStates[0], {
     type: dynamics.spring,
     frequency: 0,
     friction: 490,
     anticipationStrength: 150,
     anticipationSize: 250,
     duration: 500
    })

  show = ->
    el.style.pointerEvents = 'auto'
    for i in [0..texts.length - 1]
      text = texts[i]
      dynamics.animate(text, {
        opacity: 1,
        translateY: 0
      }, {
        type: dynamics.spring,
        frequency: 300,
        friction: 800,
        duration: 2000,
        delay: 500 + i * 70
      })

  hide = (animated = true, options = {}) ->
    el.style.pointerEvents = 'none'
    hideCloseButton()
    for i in [0..texts.length - 1]
      text = texts[i]
      if text.parentNode.tagName.toLowerCase() == 'h2'
        h = 24
      else
        h = 32
      dynamics.animate(text, {
        opacity: 0,
        translateY: h
      }, {
        type: dynamics.easeInOut,
        duration: 200,
        animated: animated,
        complete: options.complete
      })

  hide(false, {
    complete: =>
      el.style.display = ''
  })

  {
    show: show,
    hide: hide,
    closeButtonEl: closeButtonEl,
    button: button
  }
)()

class Loading
  constructor: (el) ->
    @el = el
    @dots = @el.querySelectorAll('span.dot')
    @current = 0
    @animated = false
    @hiddenIndexes = []

  start: =>
    return if @animated
    @animated = true
    @tick()
    @interval = setInterval(@tick, 500)

  tick: =>
    dot = @dots[@current]
    if @stopping
      dynamics.animate(dot.querySelector("span"), {
        opacity: 0
      }, {
        type: dynamics.easeInOut,
        duration: 300,
        delay: 350
      })
      @hiddenIndexes.push(@current)
    dynamics.animate(dot, {
      translateY: -10
    }, {
      type: dynamics.forceWithGravity,
      bounce: 60,
      gravity: 1300
    })
    @current += 1
    if @current > 2
      @current = 0
    if @hiddenIndexes.indexOf(@current) != -1
      clearInterval(@interval) if @interval
      @hiddenIndexes = []

  stop: =>
    return unless @animated
    @stopping = true
    @animated = false

loading = new Loading(document.querySelector('header .loading'))
loading.start()

cart = (->
  cartEl = document.querySelector('header a#cart')
  closeEl = document.querySelector('header a#closeCart')
  cartLabelEl = cartEl.querySelector('.label')
  cartSection = {
    el: document.querySelector('#cartSection'),
    items: document.querySelector('#cartSection .items'),
    footer: document.querySelector('#cartSection .footer')
  }
  currentCartLabelEl = null
  items = []

  setCartSectionVisibility = (visible, options = {}) ->
    options.animated ?= true
    show = ->
      cartSection.el.style.pointerEvents = 'auto'
      dynamics.animate(cartSection.footer, {
        translateY: 0
      }, {
        type: dynamics.spring,
        frequency: 250,
        friction: 1200,
        duration: 3500,
        animated: options.animated,
      })
      dynamics.animate(cartSection.items, {
        translateY: 0
        opacity: 1
      }, {
        type: dynamics.spring,
        frequency: 250,
        friction: 1200,
        duration: 3500,
        animated: options.animated,
        delay: if options.animated then 100 else 0,
        complete: options.complete,
      })

    hide = ->
      cartSection.el.style.pointerEvents = 'none'
      dynamics.animate(cartSection.footer, {
        translateY: 260
      }, {
        type: dynamics.easeInOut,
        duration: 700,
        animated: options.animated,
        complete: options.complete,
        delay: if options.animated then 200 else 0
      })
      dynamics.animate(cartSection.items, {
        translateY: 260,
        opacity: 0
      }, {
        type: dynamics.easeInOut,
        duration: 700,
        animated: options.animated,
      })

    if visible
      show()
    else
      hide()

  setCartSectionVisibility(false, {
    animated: false,
    complete: =>
      cartSection.el.style.display = ''
  })

  setCloseButtonVisibility = (visible, options = {}) ->
    options.animated ?= true
    opacityAnimationOptions = {
      type: dynamics.easeInOut,
      duration: 200,
      animated: options.animated
    }
    showElement = (el) ->
      dynamics.animate(el, {
        scaleX: 1,
        opacity: 1
      }, {
        type: dynamics.spring,
        frequency: 250,
        friction: 300,
        duration: 700,
        animated: options.animated,
        delay: 150
      })

    hideElement = (el) ->
      dynamics.animate(el, {
        scaleX: 0.01,
        opacity: 0
      }, {
        type: dynamics.easeInOut,
        duration: 300,
        animated: options.animated
      })

    if visible
      showElement(closeEl)
      hideElement(cartEl)
    else
      showElement(cartEl)
      hideElement(closeEl)

  setCloseButtonVisibility(false, { animated: false })

  addItem = (item) ->
    if currentCartLabelEl
      dynamics.animate(currentCartLabelEl, {
        translateY: 6,
        opacity: 0
      }, {
        type: dynamics.easeInOut,
        duration: 250
      })

    items.push(item)
    currentCartLabelEl = cartLabelEl.cloneNode()
    currentCartLabelEl.innerHTML = items.length
    dynamics.css(currentCartLabelEl, {
      translateY: -6,
      opacity: 0
    })
    cartEl.appendChild(currentCartLabelEl)
    cartEl.className = 'filled'
    dynamics.animate(currentCartLabelEl, {
      translateY: 0,
      opacity: 1
    }, {
      type: dynamics.gravity,
      bounciness: 600,
      duration: 800
    })

  {
    addItem: addItem
    open: ->
      fade.show()
      setCloseButtonVisibility(true)
      setCartSectionVisibility(true)
    close: ->
      setTimeout =>
        fade.hide()
      , 450
      setCloseButtonVisibility(false)
      setCartSectionVisibility(false)
  }
)()

grid = (->
  gridEl = document.querySelector('#grid')
  productEl = document.querySelector('#product')
  cartEl = document.querySelector('header a#cart')
  closeCartEl = document.querySelector('header a#closeCart')

  class Item
    constructor: (i) ->
      @index = i

      @el = document.createElement('a')
      @el.className = "item"
      @img = document.createElement('img')
      @el.appendChild(@img)

      @img.addEventListener('load', @imgLoaded)

      @el.addEventListener('mouseover', @itemOver)
      @el.addEventListener('mouseout', @itemOut)
      @el.addEventListener('click', @itemClick)

    load: =>
      @img.src = "./img/socks/socks-#{@index}.jpg"

    setDisabled: (@disabled) =>

    itemOver: =>
      return if @disabled
      dynamics.animate(@el, {
        scale: 1.18,
        opacity: 1
      }, {
        type: dynamics.spring,
        frequency: 250,
        duration: 300
      })

    itemOut: =>
      return if @disabled
      dynamics.animate(@el, {
        scale: 1
      }, {
        type: dynamics.spring,
        duration: 1500
      })

    show: =>
      dynamics.css(@el, {
        opacity: 0,
        scale: 0.01
      })
      gridEl.appendChild(@el)
      dynamics.animate(@el, {
        scale: 1,
        opacity: 1
      }, {
        type: dynamics.spring,
        friction: 300,
        frequency: 200,
        duration: 2000,
        delay: @index * 20
      })

    absolutePosition: =>
      offset = cumulativeOffset(@el)
      productOffset = cumulativeOffset(productEl)
      {
        top: offset.top - window.scrollY - productOffset.top,
        left: offset.left - window.scrollX - productOffset.left
      }

    itemClick: =>
      return if @disabled
      fade.show()
      logo.show()
      product.show()
      pos = @absolutePosition()
      @clonedEl = @el.cloneNode(true)
      @clonedEl.addEventListener 'click', @close
      dynamics.css(@clonedEl, {
        position: 'absolute',
        top: pos.top,
        left: pos.left,
        zIndex: 100,
      })
      productEl.appendChild(@clonedEl)
      @el.classList.add('hidden')
      dynamics.animate(@clonedEl, {
        translateX: -pos.left + 40,
        translateY: -pos.top + 60
        scale: 2,
        opacity: 1
      }, {
        type: dynamics.spring,
        friction: 600,
        frequency: 100,
        anticipationSize: 140,
        anticipationStrength: 50,
        duration: 2000
      })
      @clicked?()

    animateClonedEl: (properties = {}, options = {}, noAnimation = true) =>
      dynamics.setTimeout =>
        dynamics.css(@clonedEl, {
          zIndex: 1,
        })
      , 400
      pos = @absolutePosition()
      cloneElPos = cumulativeOffset(@clonedEl)
      cloneElPos.top += window.scrollY
      cloneElPos.left += window.scrollX
      productEl.removeChild(@clonedEl)
      document.body.appendChild(@clonedEl)
      dynamics.css(@clonedEl, {
        top: cloneElPos.top,
        left: cloneElPos.left
      })

      options.complete = =>
        unless noAnimation
          dynamics.css(@el, {
            scale: 0.01
          })
          dynamics.animate(@el, {
            scale: 1
          }, {
            type: dynamics.spring,
            friction: 600,
            frequency: 200,
            anticipationSize: 140,
            anticipationStrength: 50,
            duration: 2000
          })
        @el.classList.remove('hidden')
        document.body.removeChild(@clonedEl)
        @clonedEl = null

      dynamics.animate(@clonedEl, properties, options)

    close: (callback) =>
      fade.hide()
      logo.updateOffset(animated: true)
      product.hide()
      pos = @absolutePosition()
      @animateClonedEl({
        translateX: - parseInt(@clonedEl.style.left, 10) + pos.left,
        translateY: - parseInt(@clonedEl.style.top, 10) + pos.top,
        scale: 1,
        opacity: 1
      }, {
        type: dynamics.spring,
        friction: 600,
        frequency: 100,
        duration: 1200
      })
      setTimeout =>
        callback?()
      , 500

    addToCart: =>
      fade.hide()
      logo.updateOffset(animated: true)
      product.hide()

      pos = cumulativeOffset(@el)
      offset = cumulativeOffset(cartEl)
      offset.left += 27
      properties = {
        translateX: offset.left - pos.left - 32,
        translateY: offset.top - pos.top - 48,
        scale: 0.2,
        opacity: 0
      }
      @animateClonedEl(properties, {
        type: dynamics.spring,
        frequency: 30,
        friction: 200,
        anticipationStrength: 140,
        anticipationSize: 220,
        duration: 700
      }, false)

    imgLoaded: =>
      @img.className = "loaded"
      @loaded?()

  items = []
  loadedCount = 0
  currentItem = null
  showItems = ->
    loading.stop()
    for item in items
      item.show()
  itemLoaded = ->
    loadedCount += 1
    if loadedCount >= items.length
      showItems()
  itemClicked = ->
    currentItem = @

  for i in [1..SOCKS_COUNT]
    item = new Item(i)
    item.loaded = itemLoaded
    item.clicked = itemClicked
    items.push(item)
  for item in items
    item.load()

  cartEl.addEventListener 'click', ->
    grid.closeCurrentItem ->
      cart.open()
    windowWidth = window.innerWidth
    windowHeight = window.innerHeight
    return
    for i, item of items
      do (item) ->
        item.setDisabled(true)
        offset = cumulativeOffset(item.el)
        delay = Math.abs(offset.left - (windowWidth / 2)) / (windowWidth / 2) +
                offset.top / windowHeight
        delay *= 500
        translateX = offset.left - (windowWidth / 2)
        dynamics.animate(item.el, {
          translateY: -offset.top + 160,
          translateX: translateX,
          rotate: Math.round(Math.random() * 90 - 45)
        }, {
          type: dynamics.bezier,
          delay: delay,
          duration: 450,
          points: [{"x":0,"y":0,"cp":[{"x":0.2,"y":0}]},{"x":1,"y":1,"cp":[{"x":0.843,"y":0.351}]}],
          complete: =>
            item.el.style.visibility = 'hidden'
        })

  closeCartEl.addEventListener 'click', ->
    cart.close()
    windowWidth = window.innerWidth
    windowHeight = window.innerHeight

  closeCurrentItem = (callback) ->
    if currentItem?
      currentItem.close(callback)
    else
      callback()
    currentItem = null

  addToCartCurrentItem = ->
    if currentItem?
      dynamics.setTimeout cart.addItem.bind(cart, currentItem), 500
      currentItem.addToCart()
    currentItem = null

  {
    closeCurrentItem: closeCurrentItem,
    addToCartCurrentItem: addToCartCurrentItem
  }
)()

(->
  window.addEventListener 'scroll', logo.updateOffset
  window.addEventListener 'keyup', (e) =>
    if e.keyCode == 27
      # escape
      grid.closeCurrentItem()

  product.closeButtonEl.addEventListener 'click', grid.closeCurrentItem
  product.button.addEventListener 'click', grid.addToCartCurrentItem
)()

mocha = require('mocha')
jsdom = require('mocha-jsdom')
expect = require('chai').expect
assert = require('chai').assert
dynamics = require('../src/dynamics')

jsdom()

dynamics.tests =
  matrixForTransform: (transform) ->
    if transform == "translateX(50px) rotateZ(45deg)"
      return "matrix3d(0.7071067811865476, 0.7071067811865475, 0, 0, -0.7071067811865475, 0.7071067811865476, 0, 0, 0, 0, 1, 0, 50, 0, 0, 1)"

expectEqualMatrix3d = (a, b) ->
  r = /matrix3?d?\(([-0-9, \.]*)\)/
  argsA = a.match(r)?[1].split(',')
  argsB = b.match(r)?[1].split(',')
  for i in [0...argsA.length]
    expect(Math.abs(parseFloat(argsA[i]) - parseFloat(argsB[i]))).to.be.below(0.00001)

describe 'dynamics.css', ->
  it 'apply css to a DOM element', ->
    el = document.createElement('div')
    dynamics.css(el, {
      left: 0,
      top: "5px",
      backgroundColor: "#FF0000"
    })
    expect(el.style.left).eql('0px')
    expect(el.style.top).eql('5px')
    expect(el.style.backgroundColor).eql('rgb(255, 0, 0)')

  it 'apply transform to a DOM element', ->
    el = document.createElement('div')
    dynamics.css(el, {
      translateX: 10,
      translateY: "0px",
      translateZ: "25%",
      rotateZ: "90deg",
      rotateX: 45,
      skewX: 10,
      scale: 2
    })
    expect(el.style.transform).eql("translateX(10px) translateY(0px) translateZ(25%) rotateZ(90deg) rotateX(45deg) skewX(10deg) scaleX(2) scaleY(2) scaleZ(2)")

  it 'works with an array of DOM element', ->
    els = [
      document.createElement('div'),
      document.createElement('div')
    ]
    dynamics.css(els, {
      left: "10px"
    })
    expect(els[0].style.left).eql('10px')
    expect(els[1].style.left).eql('10px')

describe 'dynamics.animate', ->
  it 'animate position properties of a DOM element', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100,
      top: "50px",
      translateX: 50,
      rotateZ: 45
    }, {
      duration: 25,
      type: dynamics.easeInOut
    })
    setTimeout ->
      expect(el.style.left).eql("100px")
      expect(el.style.top).eql("50px")
      expectEqualMatrix3d(el.style.transform, dynamics.tests.matrixForTransform("translateX(50px) rotateZ(45deg)"))
      done()
    , 50

  it 'animate scrollTop of a DOM element', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      scrollTop: 100,
    }, {
      duration: 25,
      type: dynamics.easeInOut
    })
    setTimeout ->
      expect(el.scrollTop).eql('100')
      done()
    , 50

  it 'animate with a delay', (done) ->
    el = document.createElement('div')
    el.style.left = 0
    dynamics.animate(el, {
      left: 100
    }, {
      duration: 25,
      delay: 100,
      type: dynamics.easeInOut
    })
    setTimeout ->
      expect(el.style.left).eql("0px")
    , 50
    setTimeout ->
      expect(el.style.left).not.eql("100px")
    , 110
    setTimeout ->
      expect(el.style.left).eql("100px")
      done()
    , 150

  it 'works with an array of elements', (done) ->
    els = [
      document.createElement('div'),
      document.createElement('div')
    ]
    el0asserted = false
    el1asserted = false
    dynamics.animate(els, {
      left: 100,
    }, {
      duration: 25,
      complete: (el) ->
        el0asserted = true if el == els[0]
        el1asserted = true if el == els[1]
    })
    setTimeout ->
      expect(els[0].style.left).eql("100px")
      expect(els[1].style.left).eql("100px")
      assert(el0asserted, "complete wasn't called with the right element")
      assert(el1asserted, "complete wasn't called with the right element")
      done()
    , 50

  it 'calls change while the animation is running', (done) ->
    el = document.createElement('div')
    changeCalls = 0
    dynamics.animate(el, {
      left: 100,
      top: "50px"
    }, {
      duration: 100,
      type: dynamics.easeInOut,
      change: ->
        changeCalls += 1
    })
    setTimeout ->
      expect(changeCalls).to.be.above(1)
      done()
    , 150

  it 'calls change with element being animated', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100,
      top: "50px"
    }, {
      duration: 100,
      type: dynamics.easeInOut,
      change: (element) ->
        assert(el == element, "Element should be the same")
    })
    setTimeout ->
      done()
    , 150

  it 'calls change with progress incrementing', (done) ->
    el = document.createElement('div')
    savedProgress = -1
    dynamics.animate(el, {
      left: 100,
      top: "50px"
    }, {
      duration: 100,
      type: dynamics.easeInOut,
      change: (el, progress) ->
        assert(progress > savedProgress, "Progress should increment")
        assert(progress >= 0 && progress <= 1, "Progress should be in [0, 1] range")
        savedProgress = progress
    })
    setTimeout ->
      assert(savedProgress == 1, "Progress should end with 1")
      done()
    , 150

  it 'actually animates properties while the animation is running', (done) ->
    el = document.createElement('div')
    previous = { left: 0, top: 0, translateX: 0, rotateZ: 0, transform: 'none' }
    dynamics.animate(el, {
      left: 100,
      top: "50px",
      translateX: 50,
      rotateZ: 45
    }, {
      duration: 100,
      type: dynamics.easeInOut
    })
    interval = setInterval ->
      current = { left: parseFloat(el.style.left), top: parseFloat(el.style.top), transform: el.style.transform }
      assert(current.left >= previous.left, "Left should increment")
      assert(current.top >= previous.top, "Top should increment")
      assert(current.transform != previous.transform or (current.transform == previous.transform && current.transform != "none"), "Transform should change")
      previous = current
    , 20
    setTimeout ->
      clearInterval(interval)
      done()
    , 150

  it 'calls complete when the animation is over', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100,
      top: "50px"
    }, {
      duration: 25,
      complete: ->
        done()
    })

  it 'comes back to the original value with dynamics.bounce', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100
    }, {
      duration: 25,
      type: dynamics.bounce,
      complete: ->
        expect(el.style.left).eql("0px")
        done()
    })

  it 'animates the points of a svg element correctly', (done) ->
    regex = /M([.\d]*),([.\d]*) C([.\d]*),([.\d]*)/
    dynamics.tests.isSVG = (el) ->
      true
    el = document.createElement('polygon')
    el.setAttribute("points", "M101.88,22 C101.88,18.25")
    previous = el.getAttribute("points").match(regex)
    dynamics.animate(el, {
      points: "M50,10 C88.11,20.45"
    }, {
      duration: 100
    })
    interval = setInterval ->
      current = el.getAttribute("points").match(regex)
      assert(current?)
      expect(parseFloat(current[1])).to.at.most(parseFloat(previous[1]))
      expect(parseFloat(current[2])).to.at.most(parseFloat(previous[2]))
      expect(parseFloat(current[3])).to.at.most(parseFloat(previous[3]))
      expect(parseFloat(current[4])).to.at.least(parseFloat(previous[4]))
      previous = current
    , 20
    setTimeout ->
      clearInterval(interval)
      expect(el.getAttribute("points")).to.be.equal("M50,10 C88.11,20.45")
      done()
    , 150


  it 'animates the points of a svg path correctly', (done) ->
    el = document.createElement('path')

    # On chrome 52 getComputedStyle give a "d" property for path
    # Mock window.getComputedStyle
    style = window.getComputedStyle(el, null)
    style.setProperty('d', 'path(10 20 30)')
    oldComputed = window.getComputedStyle
    window.getComputedStyle = (el, pseudoElt) -> style

    dynamics.tests.isSVG = (el) -> true
    el.setAttribute("d", "M101.88,22 C101.88,18.25")
    dynamics.animate(el, {
      d: "M50,10 C88.11,20.45"
    }, {
      duration: 100
    })
    setTimeout ->
      expect(el.getAttribute("d")[0]).to.be.equal('M')
      window.getComputedStyle = oldComputed # remove mock to avoid conflict for the next test
      done()
    , 50

  it 'animates properties of an object correctly', (done) ->
    assertTypes = (object) ->
      expect(typeof(object.number)).to.be.equal('number', 'object.number has the wrong type')
      expect(typeof(object.negative)).to.be.equal('number', 'object.negative has the wrong type')
      expect(typeof(object.string)).to.be.equal('string', 'object.string has the wrong type')
      expect(typeof(object.stringArray)).to.be.equal('string', 'object.stringArray has the wrong type')
      assert(object.array instanceof Array, 'object.array has the wrong type')
      expect(typeof(object.hexColor)).to.be.equal('string', 'object.hexColor has the wrong type')
      expect(typeof(object.rgbColor)).to.be.equal('string', 'object.rgbColor has the wrong type')
      expect(typeof(object.rgbaColor)).to.be.equal('string', 'object.rgbaColor has the wrong type')
      expect(typeof(object.background)).to.be.equal('string', 'object.background has the wrong type')

    assertFormats = (object) ->
      assert(object.stringArray.match(/^([.\d]*) ([.\d]*), d([.\d]*):([.\d]*)$/)?, 'object.stringArray has the wrong format')
      assert(object.array[0].match(/^([.\d]*)deg$/)?, 'object.array[0] has the wrong format')
      assert(object.array[2].match(/^([.\d]*)$/)?, 'object.array[2] has the wrong format')
      assert(object.array[4].match(/^#([a-zA-Z\d]{6})$/)?, 'object.array[4] has the wrong format')
      assert(object.hexColor.match(/^#([a-zA-Z\d]{6})$/)?, 'object.hexColor has the wrong format')
      assert(object.rgbColor.match(/^rgb\(([.\d]*), ([.\d]*), ([.\d]*)\)$/)?, 'object.rgbColor has the wrong format')
      assert(object.rgbaColor.match(/^rgba\(([.\d]*), ([.\d]*), ([.\d]*), ([.\d]*)\)$/)?, 'object.rgbaColor has the wrong format')
      assert(object.background.match(/^linear-gradient\(#([a-zA-Z\d]{6}), #([a-zA-Z\d]{6})\)$/)?, 'object.background has the wrong format')

    object = {
      number: 0,
      negative: -10,
      string: "10",
      stringArray: "10 50, d10:50",
      array: ["0deg", 0, "1.10", 10, "#FFFFFF"],
      hexColor: "#FFFFFF",
      rgbColor: "rgb(255, 255, 255)",
      rgbaColor: "rgba(255, 255, 255, 0)",
      translateX: 0,
      rotateZ: 0,
      background: "linear-gradient(#FFFFFF, #000000)",
    }
    previous = JSON.parse(JSON.stringify(object))
    dynamics.animate(object, {
      number: 10,
      negative: 50,
      string: "50",
      stringArray: "100 1, d0:100",
      array: ["100deg", 40, "2.20", 20, "#123456"],
      hexColor: "#123456",
      rgbColor: "rgb(18, 52, 86)",
      rgbaColor: "rgba(18, 52, 86, 1)",
      translateX: 10,
      rotateZ: 1,
      background: "linear-gradient(#FF0000, #F0F0F0)",
    }, {
      duration: 100
    })
    interval = setInterval ->
      current = JSON.parse(JSON.stringify(object))

      assertTypes(current)
      assertFormats(current)

      # Assert values are changing
      expect(current.number).to.at.least(previous.number)
      expect(current.negative).to.at.least(previous.negative)
      expect(parseFloat(current.string)).to.at.least(parseFloat(previous.string))
      stringArrayArgs = current.stringArray.match(/^([.\d]*) ([.\d]*), d([.\d]*):([.\d]*)$/)
      previousStringArrayArgs = previous.stringArray.match(/^([.\d]*) ([.\d]*), d([.\d]*):([.\d]*)$/)
      expect(parseFloat(stringArrayArgs[1])).to.at.least(parseFloat(previousStringArrayArgs[1]))
      expect(parseFloat(stringArrayArgs[2])).to.at.most(parseFloat(previousStringArrayArgs[2]))
      expect(parseFloat(stringArrayArgs[3])).to.at.most(parseFloat(previousStringArrayArgs[3]))
      expect(parseFloat(stringArrayArgs[4])).to.at.least(parseFloat(previousStringArrayArgs[4]))

      previous = current
    , 20
    setTimeout ->
      clearInterval(interval)
      assertTypes(object)
      assertFormats(object)

      done()
    , 150

  it 'animates actual properties of an object correctly', (done) ->
    object = {}
    Object.defineProperty(object, "prop", {
      set: (v) ->
        @_prop = v
      get: ->
        @_prop
    })
    object.prop = 1

    dynamics.animate(object, {
      prop: 0
    }, {
      duration: 100
    })

    previousProp = object.prop

    interval = setInterval ->
      assert(object.prop >= 0 && object.prop <= 1, "prop is between 0 and 1")
      assert(object.prop < previousProp || object.prop == 0, "prop should be decreasing or equal 0")

      previousProp = object.prop
    , 20

    setTimeout ->
      clearInterval(interval)
      expect(object.prop).to.be.equal(0, 'object.prop has the wrong end value')

      done()
    , 150

  it 'finishes the animation with the correct end state while using a specific bezier curve', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100,
    }, {
      duration: 25,
      type: dynamics.bezier,
      points: [
        {"x":0,"y":0,"cp":[{"x":0,"y":1}]},
        {"x":1,"y":0,"cp":[{"x":0.5,"y":0}]}
      ],
      complete: ->
        expect(el.style.left).eql('0px')
        done()
    })

describe 'dynamics.stop', ->
  it 'actually stops current animation', (done) ->
    el = document.createElement('div')
    changeCanBeCalled = true
    dynamics.animate(el, {
      left: 100
    }, {
      duration: 100,
      type: dynamics.easeInOut,
      change: ->
        assert(changeCanBeCalled, "change shouldn't be called anymore")
      ,
      complete: ->
        assert(false, "complete shouldn't be called")
    })
    setTimeout ->
      dynamics.stop(el)
      changeCanBeCalled = false
    , 50
    setTimeout ->
      done()
    , 150

  it 'also works with a delayed animation', (done) ->
    el = document.createElement('div')
    dynamics.animate(el, {
      left: 100
    }, {
      duration: 100,
      delay: 100,
      change: ->
        assert(false, "change shouldn't be called")
      ,
      complete: ->
        assert(false, "complete shouldn't be called")
    })
    setTimeout ->
      dynamics.stop(el)
    , 50
    setTimeout ->
      done()
    , 150

  it 'also works with multiple delayed animations', (done) ->
    els = [document.createElement('div'), document.createElement('div'), document.createElement('div')]
    delay = 100
    for el in els
      dynamics.animate(el, {
        left: 100
      }, {
        duration: 100,
        delay: delay,
        change: ->
          assert(false, "change shouldn't be called")
        ,
        complete: ->
          assert(false, "complete shouldn't be called")
      })
      delay += 50
    setTimeout ->
      for el in els
        dynamics.stop(el)
    , 50
    setTimeout ->
      done()
    , 450

describe 'curves', ->
  describe 'dynamics.linear', ->
    it 'works', ->
      curve = dynamics.linear()
      expect(curve(0)).eql(0)
      expect(curve(0.1)).eql(0.1)
      expect(curve(5)).eql(5)
      expect(curve(5.6)).eql(5.6)
      expect(curve(7.8)).eql(7.8)
      expect(curve(1)).eql(1)

  describe 'dynamics.easeInOut', ->
    it 'works', ->
      curve = dynamics.easeInOut()
      expect(curve(0)).eql(0)
      assert(curve(0.25) > 0 && curve(0.25) < 0.5)
      expect(curve(0.5)).eql(0.5)
      assert(curve(0.75) > 0.5 && curve(0.75) < 1)
      expect(curve(1)).eql(1)

  describe 'dynamics.easeIn', ->
    it 'increases exponentially', ->
      curve = dynamics.easeIn()
      inter = 0.1
      diff = 0
      for i in [1..10]
        t1 = inter * (i - 1)
        t2 = inter * i
        newDiff = curve(t2) - curve(t1)
        assert(newDiff > diff, "easeIn should be exponential")
        diff = newDiff

  describe 'dynamics.easeOut', ->
    it 'increases 1/exponentially', ->
      curve = dynamics.easeOut()
      inter = 0.1
      diff = 1
      for i in [1..10]
        t1 = inter * (i - 1)
        t2 = inter * i
        newDiff = curve(t2) - curve(t1)
        assert(newDiff < diff, "easeOut should be 1/exponential")
        diff = newDiff

  describe 'dynamics.bounce', ->
    it 'starts and returns to initial state', ->
      curve = dynamics.bounce()
      assert(curve(0) < 0.001 && curve(0) >= 0)
      assert(curve(1) < 0.001 && curve(1) >= 0)

  describe 'dynamics.forceWithGravity', ->
    it 'starts and returns to initial state', ->
      curve = dynamics.forceWithGravity()
      assert(curve(0) < 0.001 && curve(0) >= 0)
      assert(curve(1) < 0.001 && curve(1) >= 0)

describe 'dynamics.setTimeout', ->
  it 'works', (done) ->
    t = Date.now()
    dynamics.setTimeout(->
      assert(Math.abs(Date.now() - t - 100) < 30)
      done()
    , 100)

describe 'dynamics.clearTimeout', ->
  it 'works', (done) ->
    i = dynamics.setTimeout(->
      assert(false)
    , 100)
    dynamics.clearTimeout(i)
    setTimeout(->
      done()
    , 200)

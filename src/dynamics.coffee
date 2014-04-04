# Private Classes
## Dynamics
class Dynamic
  @properties: {}

  constructor: (@options = {}) ->
    for k, v of @options.type.properties
      if !@options[k]? and !v.editable
        @options[k] = v.default

  init: =>
    @t = 0

  next: (step) =>
    @t = 1 if @t > 1
    r = @at(@t)
    @t += step
    r

  at: (t) =>
    [t, t]

class Linear extends Dynamic
  @properties:
    duration: { min: 100, max: 4000, default: 1000 }

  init: =>
    super

  at: (t) =>
    [t, t]

class Gravity extends Dynamic
  @properties:
    bounce: { min: 0, max: 80, default: 40 }
    gravity: { min: 1, max: 4000, default: 1000 }
    expectedDuration: { editable: false }

  constructor: (@options = {}) ->
    @initialForce ?= false
    @options.duration = @duration()
    super @options

  expectedDuration: =>
    @duration()

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
    if @initialForce
      curve.a = 0
      curve.b = curve.b * 2
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
    if @initialForce
      curve.a = 0
      curve.b = curve.b * 2
    @curves.push curve
    while curve.b < 1 and curve.H > 0.001
      L = curve.b - curve.a
      curve = { a: curve.b, b: curve.b + L * bounce, H: curve.H * bounce * bounce }
      @curves.push curve

  curve: (a, b, H, t) =>
    L = b - a
    t2 = (2 / L) * (t) - 1 - (a * 2 / L)
    c = t2 * t2 * H - H + 1
    c = 1 - c if @initialForce
    c

  at: (t) =>
    bounce = (@options.bounce / 100)
    gravity = @options.gravity

    i = 0
    curve = @curves[i]
    while(!(t >= curve.a and t <= curve.b))
      i += 1
      curve = @curves[i]
      break unless curve

    if !curve
      if @initialForce
        v = 0
      else
        v = 1
    else
      v = @curve(curve.a, curve.b, curve.H, t)

    [t, v]

class GravityWithForce extends Gravity
  returnsToSelf: true

  constructor: (@options = {}) ->
    @initialForce = true
    super @options

class Spring extends Dynamic
  @properties:
    frequency: { min: 0, max: 100, default: 15 }
    friction: { min: 1, max: 1000, default: 200 }
    anticipationStrength: { min: 0, max: 1000, default: 0 }
    anticipationSize: { min: 0, max: 99, default: 0 }
    duration: { min: 100, max: 4000, default: 1000 }

  at: (t) =>
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

class SelfSpring extends Dynamic
  @properties:
    frequency: { min: 0, max: 100, default: 15 }
    friction: { min: 1, max: 1000, default: 200 }
    duration: { min: 100, max: 4000, default: 1000 }

  returnsToSelf: true

  at: (t) =>
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

class Bezier extends Dynamic
  @properties:
    points: { type: 'points', default: [{"x":0,"y":0,"controlPoints":[{"x":0.2,"y":0}]},{"x":0.574,"y":1.208,"controlPoints":[{"x":0.291,"y":1.199},{"x":0.806,"y":1.19}]},{"x":1,"y":1,"controlPoints":[{"x":0.846,"y":1}]}] }
    duration: { min: 100, max: 4000, default: 1000 }

  constructor: (@options = {}) ->
    @returnsToSelf = @options.points[@options.points.length - 1].y == 0
    super @options

  B_: (t, p0, p1, p2, p3) =>
    (Math.pow(1 - t, 3) * p0) + (3 * Math.pow(1 - t, 2) * t * p1) + (3 * (1 - t) * Math.pow(t, 2) * p2) + Math.pow(t, 3) * p3

  B: (t, p0, p1, p2, p3) =>
    {
      x: @B_(t, p0.x, p1.x, p2.x, p3.x),
      y: @B_(t, p0.y, p1.y, p2.y, p3.y)
    }

  yForX: (xTarget, Bs) =>
    # Find the right Bezier curve first
    B = null
    for aB in Bs
      if xTarget >= aB(0).x and xTarget <= aB(1).x
        B = aB
      break if B != null

    unless B
      if @returnsToSelf
        return 0
      else
        return 1

    # Find the percent with dichotomy
    xTolerance = 0.0001
    lower = 0
    upper = 1
    percent = (upper + lower) / 2

    x = B(percent).x
    i = 0

    while Math.abs(xTarget - x) > xTolerance and i < 100
      if xTarget > x
        lower = percent
      else
        upper = percent

      percent = (upper + lower) / 2
      x = B(percent).x
      i += 1

    # Returns y at this specific percent
    return B(percent).y;

  at: (t) =>
    x = t
    points = @options.points || Bezier.properties.points.default
    Bs = []
    for i of points
      k = parseInt(i)
      break if k >= points.length - 1
      ((pointA, pointB) =>
        B = (t) =>
          @B(t, pointA, pointA.controlPoints[pointA.controlPoints.length - 1], pointB.controlPoints[0], pointB)
        Bs.push(B)
      )(points[k], points[k + 1])
    y = @yForX(x, Bs)
    [x, y]

class EaseInOut extends Dynamic
  @properties:
    friction: { min: 1, max: 1000, default: 500 }
    duration: { min: 100, max: 4000, default: 1000 }

  constructor: (@options = {}) ->
    super
    friction = @options.friction || EaseInOut.properties.friction.default
    points = [
      {
        "x":0,
        "y":0,
        "controlPoints":[{
          "x":1 - (friction / 1000),
          "y":0
        }]
      },
      {
        "x":1,
        "y":1,
        "controlPoints":[{
          "x":friction / 1000,
          "y":1
        }]
      }
    ]
    @bezier = new Bezier({
      type: Bezier,
      duration: @options.duration,
      points: points
    })

  at: (t) =>
    @bezier.at(t)

## Helpers
cacheFn = (func) ->
  data = {}
  cachedMethod = ->
    key = ""
    for k in arguments
      key += k.toString() + ","
    result = data[key]
    unless result
      data[key] = result = func.apply(this, arguments)
    result
  cachedMethod

class BrowserSupport
  @transform: ->
    @withPrefix("transform")

  @keyframes: ->
    return "-webkit-keyframes" if document.body.style.webkitAnimation != undefined
    return "-moz-keyframes" if document.body.style.mozAnimation != undefined
    "keyframes"

  @withPrefix: (property) ->
    prefix = @prefixFor(property)
    return "#{prefix}#{property.substring(0, 1).toUpperCase() + property.substring(1)}" if prefix == 'Moz'
    return "-#{prefix.toLowerCase()}-#{property}" if prefix != ''
    property

  @prefixFor: cacheFn (property) ->
    propArray = property.split('-')
    propertyName = ""
    for prop in propArray
      propertyName += prop.substring(0, 1).toUpperCase() + prop.substring(1)
    for prefix in [ "Webkit", "Moz" ]
      k = prefix + propertyName
      if document.body.style[k] != undefined
        return prefix
    ''

# Additional vector tools
VectorTools = {}
VectorTools.length = (vector) ->
  a = 0
  for e in vector.elements
    a += Math.pow(e, 2)
  Math.sqrt(a)
VectorTools.normalize = (vector) ->
  length = VectorTools.length(vector)
  newElements = []
  for i, e of vector.elements
    newElements[i] = e / length
  Vector.create(newElements)
VectorTools.combine = (a, b, ascl, bscl) ->
  result = []
  result[0] = (ascl * a.elements[0]) + (bscl * b.elements[0])
  result[1] = (ascl * a.elements[1]) + (bscl * b.elements[1])
  result[2] = (ascl * a.elements[2]) + (bscl * b.elements[2])
  return Vector.create(result)

# Matrix tools
MatrixTools = {}
MatrixTools.decompose = (matrix) ->
  translate = []
  scale = []
  skew = []
  quaternion = []
  perspective = []

  if (matrix.elements[3][3] == 0)
    return false

  # Normalize the matrix.
  for i in [0..3]
    for j in [0..3]
      matrix.elements[i][j] /= matrix.elements[3][3]

  # perspectiveMatrix is used to solve for perspective, but it also provides
  # an easy way to test for singularity of the upper 3x3 component.
  perspectiveMatrix = matrix.dup()

  for i in [0..2]
    perspectiveMatrix.elements[i][3] = 0
  perspectiveMatrix.elements[3][3] = 1

  # Don't do this anymore, it would return false for scale(0)..
  # if perspectiveMatrix.determinant() == 0
  #   return false

  # First, isolate perspective.
  if matrix.elements[0][3] != 0 || matrix.elements[1][3] != 0 || matrix.elements[2][3] != 0
    # rightHandSide is the right hand side of the equation.
    rightHandSide = Vector.create([
      matrix.elements[0][3],
      matrix.elements[1][3],
      matrix.elements[2][3],
      matrix.elements[3][3]
    ])

    # Solve the equation by inverting perspectiveMatrix and multiplying
    # rightHandSide by the inverse.
    inversePerspectiveMatrix = perspectiveMatrix.inverse()
    transposedInversePerspectiveMatrix = inversePerspectiveMatrix.transpose()
    perspective = transposedInversePerspectiveMatrix.multiply(rightHandSide).elements

    # Clear the perspective partition
    matrix.elements[0][3] = 0
    matrix.elements[1][3] = 0
    matrix.elements[2][3] = 0
    matrix.elements[3][3] = 1
  else
    # No perspective.
    perspective = [0,0,0,1]

  # Next take care of translation
  for i in [0..2]
    translate[i] = matrix.elements[3][i]
    matrix.elements[3][i] = 0

  # Now get scale and shear. 'row' is a 3 element array of 3 component vectors
  row = []
  for i in [0..2]
    row[i] = Vector.create([
      matrix.elements[i][0],
      matrix.elements[i][1],
      matrix.elements[i][2]
    ])

  # Compute X scale factor and normalize first row.
  scale[0] = VectorTools.length(row[0])
  row[0] = VectorTools.normalize(row[0])

  # Compute XY shear factor and make 2nd row orthogonal to 1st.
  skew[0] = row[0].dot(row[1])
  row[1] = VectorTools.combine(row[1], row[0], 1.0, -skew[0])

  # Now, compute Y scale and normalize 2nd row.
  scale[1] = VectorTools.length(row[1])
  row[1] = VectorTools.normalize(row[1])
  skew[0] /= scale[1]

  # Compute XZ and YZ shears, orthogonalize 3rd row
  skew[1] = row[0].dot(row[2])
  row[2] = VectorTools.combine(row[2], row[0], 1.0, -skew[1])
  skew[2] = row[1].dot(row[2])
  row[2] = VectorTools.combine(row[2], row[1], 1.0, -skew[2])

  # Next, get Z scale and normalize 3rd row.
  scale[2] = VectorTools.length(row[2])
  row[2] = VectorTools.normalize(row[2])
  skew[1] /= scale[2]
  skew[2] /= scale[2]

  # At this point, the matrix (in rows) is orthonormal.
  # Check for a coordinate system flip.  If the determinant
  # is -1, then negate the matrix and the scaling factors.
  pdum3 = row[1].cross(row[2])
  if row[0].dot(pdum3) < 0
    for i in [0..2]
      scale[i] *= -1
      row[i].elements[0] *= -1
      row[i].elements[1] *= -1
      row[i].elements[2] *= -1

  # Euler angles
  rotate = []
  rotate[1] = Math.asin(-row[0].elements[2])
  if Math.cos(rotate[1]) != 0
    rotate[0] = Math.atan2(row[1].elements[2], row[2].elements[2])
    rotate[2] = Math.atan2(row[0].elements[1], row[0].elements[0])
  else
    rotate[0] = Math.atan2(-row[2].elements[0], row[1].elements[1])
    rotate[1] = 0;

  # Now, get the rotations out
  t = row[0].elements[0] + row[1].elements[1] + row[2].elements[2] + 1.0
  if t > 1e-4
    s = 0.5 / Math.sqrt(t)
    w = 0.25 / s
    x = (row[2].elements[1] - row[1].elements[2]) * s
    y = (row[0].elements[2] - row[2].elements[0]) * s
    z = (row[1].elements[0] - row[0].elements[1]) * s
  else if (row[0].elements[0] > row[1].elements[1]) && (row[0].elements[0] > row[2].elements[2])
    s = Math.sqrt(1.0 + row[0].elements[0] - row[1].elements[1] - row[2].elements[2]) * 2.0
    x = 0.25 * s
    y = (row[0].elements[1] + row[1].elements[0]) / s
    z = (row[0].elements[2] + row[2].elements[0]) / s
    w = (row[2].elements[1] - row[1].elements[2]) / s
  else if row[1].elements[1] > row[2].elements[2]
    s = Math.sqrt(1.0 + row[1].elements[1] - row[0].elements[0] - row[2].elements[2]) * 2.0
    x = (row[0].elements[1] + row[1].elements[0]) / s
    y = 0.25 * s
    z = (row[1].elements[2] + row[2].elements[1]) / s
    w = (row[0].elements[2] - row[2].elements[0]) / s
  else
    s = Math.sqrt(1.0 + row[2].elements[2] - row[0].elements[0] - row[1].elements[1]) * 2.0
    x = (row[0].elements[2] + row[2].elements[0]) / s
    y = (row[1].elements[2] + row[2].elements[1]) / s
    z = 0.25 * s
    w = (row[1].elements[0] - row[0].elements[1]) / s

  quaternion[0] = x
  quaternion[1] = y
  quaternion[2] = z
  quaternion[3] = w

  for type in [translate, scale, skew, quaternion, perspective, rotate]
    for k, v of type
      type[k] = 0 if isNaN(v)

  {
    translate: translate,
    scale: scale,
    skew: skew,
    quaternion: quaternion,
    perspective: perspective,
    rotate: rotate
  }

MatrixTools.interpolate = (decomposedA, decomposedB, t) ->
  # New decomposedMatrix
  decomposed = {
    translate: [],
    scale: [],
    skew: [],
    quaternion: [],
    perspective: []
  }

  # Linearly interpolate translate, scale, skew and perspective
  for k in [ 'translate', 'scale', 'skew', 'perspective' ]
    for i in [0..decomposedA[k].length-1]
      decomposed[k][i] = (decomposedB[k][i] - decomposedA[k][i]) * t + decomposedA[k][i]

  # Interpolate quaternion
  qa = decomposedA.quaternion
  qb = decomposedB.quaternion

  ax = qa[0]
  ay = qa[1]
  az = qa[2]
  aw = qa[3]
  bx = qb[0]
  By = qb[1]
  bz = qb[2]
  bw = qb[3]

  angle = ax * bx + ay * By + az * bz + aw * bw

  if angle < 0.0
    ax = -ax
    ay = -ay
    az = -az
    aw = -aw
    angle = -angle

  if angle + 1.0 > .05
    if 1.0 - angle >= .05
      th = Math.acos(angle)
      invth = 1.0 / Math.sin(th)
      scale = Math.sin(th * (1.0 - t)) * invth
      invscale = Math.sin(th * t) * invth
    else
      scale = 1.0 - t
      invscale = t
  else
    bx = -ay
    By = ax
    bz = -aw
    bw = az
    scale = Math.sin(piDouble * (.5 - t))
    invscale = Math.sin(piDouble * t)

  cx = ax * scale + bx * invscale
  cy = ay * scale + By * invscale
  cz = az * scale + bz * invscale
  cw = aw * scale + bw * invscale

  decomposed.quaternion[0] = cx
  decomposed.quaternion[1] = cy
  decomposed.quaternion[2] = cz
  decomposed.quaternion[3] = cw

  return decomposed

MatrixTools.recompose = (decomposedMatrix) ->
  translate = decomposedMatrix.translate
  scale = decomposedMatrix.scale
  skew = decomposedMatrix.skew
  quaternion = decomposedMatrix.quaternion
  perspective = decomposedMatrix.perspective

  matrix = Matrix.I(4)

  # apply perspective
  for i in [0..3]
    matrix.elements[i][3] = perspective[i]

  # apply rotation
  x = quaternion[0]
  y = quaternion[1]
  z = quaternion[2]
  w = quaternion[3]

  # apply skew
  # temp is a identity 4x4 matrix initially
  if skew[2]
    temp = Matrix.I(4)
    temp.elements[2][1] = skew[2]
    matrix = matrix.multiply(temp)

  if skew[1]
    temp = Matrix.I(4)
    temp.elements[2][0] = skew[1]
    matrix = matrix.multiply(temp)

  if skew[0]
    temp = Matrix.I(4)
    temp.elements[1][0] = skew[0]
    matrix = matrix.multiply(temp)


  # Construct a composite rotation matrix from the quaternion values
  # rotationMatrix is a identity 4x4 matrix initially
  rotationMatrix = Matrix.I(4)
  rotationMatrix.elements[0][0] = 1 - 2 * (y * y + z * z)
  rotationMatrix.elements[0][1] = 2 * (x * y - z * w)
  rotationMatrix.elements[0][2] = 2 * (x * z + y * w)
  rotationMatrix.elements[1][0] = 2 * (x * y + z * w)
  rotationMatrix.elements[1][1] = 1 - 2 * (x * x + z * z)
  rotationMatrix.elements[1][2] = 2 * (y * z - x * w)
  rotationMatrix.elements[2][0] = 2 * (x * z - y * w)
  rotationMatrix.elements[2][1] = 2 * (y * z + x * w)
  rotationMatrix.elements[2][2] = 1 - 2 * (x * x + y * y)

  matrix = matrix.multiply(rotationMatrix)

  # apply scale
  for i in [0..2]
    for j in [0..2]
      matrix.elements[i][j] *= scale[i]

  # apply translation
  for i in [0..2]
    matrix.elements[3][i] = translate[i]

  matrix

MatrixTools.matrixToString = (matrix) ->
  str = 'matrix3d('
  for i in [0..3]
    for j in [0..3]
      str += matrix.elements[i][j]
      str += ',' unless i == 3 and j == 3
  str += ')'
  str

MatrixTools.transformStringToMatrixString = cacheFn (transform) ->
  matrixEl = document.createElement('div')
  matrixEl.style[BrowserSupport.transform()] = transform
  document.body.appendChild(matrixEl)
  style = window.getComputedStyle(matrixEl, null)
  result = style.transform || style[BrowserSupport.transform()]
  document.body.removeChild(matrixEl)
  result

Animations = []
hasCommonProperties = (props1, props2) ->
  for k, v of props1
    return true if props2[k]?
  false
stopAnimationsForEl = (el, properties) ->
  for animation in Animations
    if animation.el == el and hasCommonProperties(animation.to, properties)
      animation.stop()

# Public Methods
css = (el, properties) ->
  for k, v of properties
    el.style[BrowserSupport.withPrefix(k)] = v

# Public Classes
class Animation
  @index: 0

  constructor: (@el, @to, options = {}) ->
    if window['jQuery'] and @el instanceof jQuery
      @el = @el[0]
    @animating = false
    redraw = @el.offsetHeight # Hack to redraw the element
    @frames = @parseFrames({
      0: @getFirstFrame(@to),
      100: @to
    })
    @setOptions(options)
    if @options.debugName and Dynamics.InteractivePanel
      Dynamics.InteractivePanel.addAnimation(@)
    Animations.push(@)

  setOptions: (options = {}) =>
    optionsChanged = @options?.optionsChanged

    @options = options
    @options.duration ?= 1000
    @options.complete ?= null
    @options.type ?= Linear
    @options.animated ?= true
    @returnsToSelf = false || @dynamic().returnsToSelf
    @_dynamic = null

    if @options.debugName and Dynamics.Overrides and Dynamics.Overrides.for(@options.debugName)
      @options = Dynamics.Overrides.getOverride(@options, @options.debugName)

    @dynamic().init()

    optionsChanged?()

  dynamic: =>
    @_dynamic ?= new @options.type(@options)
    @_dynamic

  convertTransformToMatrix: (transform) =>
    MatrixTools.transformStringToMatrixString(transform)

  convertToMatrix3d: (transform) =>
    unless /matrix/.test transform
      transform = 'matrix3d(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)'
    else
      # format: matrix(a, c, b, d, tx, ty)
      match = transform.match /matrix\(([-0-9\.]*), ([-0-9\.]*), ([-0-9\.]*), ([-0-9\.]*), ([-0-9\.]*), ([-0-9\.]*)\)/
      if match
        a = parseFloat(match[1])
        b = parseFloat(match[2])
        c = parseFloat(match[3])
        d = parseFloat(match[4])
        tx = parseFloat(match[5])
        ty = parseFloat(match[6])
        transform = "matrix3d(#{a}, #{b}, 0, 0, #{c}, #{d}, 0, 0, 0, 0, 1, 0, #{tx}, #{ty}, 0, 1)"

    # format: matrix3d(a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1)
    match = transform.match /matrix3d\(([^)]*)\)/
    elements = null
    if match
      content = match[1]
      elements = content.split(',').map(parseFloat)

    matrixElements = []
    for i in [0..3]
      matrixElements.push(elements.slice(i * 4,i * 4 + 4))
    Matrix.create(matrixElements)

  getFirstFrame: (properties) =>
    frame = {}
    style = window.getComputedStyle(@el, null)
    for k of properties
      v = @el.style[BrowserSupport.withPrefix(k)]
      v = style[BrowserSupport.withPrefix(k)] unless v
      frame[k] = v
    frame

  parseFrames: (frames) =>
    newFrames = {}
    for percent, properties of frames
      newProperties = {}
      for k, v of properties
        if k != 'transform'
          vString = v + ""
          match = vString.match /([-0-9.]*)(.*)/
          value = parseFloat(match[1])
          unit = match[2]
        else
          value = MatrixTools.decompose(@convertToMatrix3d(@convertTransformToMatrix(v)))
          unit = ''
        newProperties[k] = {
          value: value,
          unit: unit
        }
      newFrames[percent] = newProperties
    newFrames

  defaultForProperty: (property) =>
    return 1 if property == 'opacity'
    0

  start: =>
    stopAnimationsForEl(@el, @to)

    unless @options.animated
      @apply(1, { progress: 1 })
      return

    @animating = true
    @ts = null
    if @stopped
      @stopped = false
    requestAnimationFrame @frame

  stop: =>
    @animating = false
    @stopped = true

  frame: (ts) =>
    return if @stopped
    t = 0
    if @ts
      dTs = ts - @ts
      t = dTs / @options.duration
    else
      @ts = ts

    at = @dynamic().at(t)

    @apply(at[1], { progress: t })

    if t < 1
      requestAnimationFrame @frame
    else
      @animating = false
      @dynamic().init()
      @options.complete?(@)

  apply: (t, args = {}) =>
    frame0 = @frames[0]
    frame1 = @frames[100]
    progress = args.progress
    progress ?= -1

    transform = ''
    properties = {}
    for k, v of frame1
      value = v.value
      unit = v.unit

      newValue = null
      if progress >= 1
        if @returnsToSelf
          newValue = frame0[k].value
        else
          newValue = frame1[k].value

      if k == 'transform'
        newValue ?= MatrixTools.interpolate(frame0[k].value, frame1[k].value, t)
        matrix = MatrixTools.recompose(newValue)
        properties['transform'] = MatrixTools.matrixToString(matrix)
      else
        unless newValue
          oldValue = null
          oldValue = frame0[k].value if frame0[k]
          oldValue = @defaultForProperty(k) unless oldValue?
          dValue = value - oldValue
          newValue = oldValue + (dValue * t)
        properties[k] = newValue

    css(@el, properties)

# Export
Dynamics =
  Animation: Animation
  Types:
    Spring: Spring
    SelfSpring: SelfSpring
    Gravity: Gravity
    GravityWithForce: GravityWithForce
    Linear: Linear
    Bezier: Bezier
    EaseInOut: EaseInOut
  css: css

try
  if module
    module.exports = Dynamics
  else
    @Dynamics = Dynamics
catch e
  @Dynamics = Dynamics

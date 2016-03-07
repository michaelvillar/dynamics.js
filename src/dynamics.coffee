# Visibility change
isDocumentVisible = ->
  document.visibilityState == "visible" || dynamics.tests?

observeVisibilityChange = (() ->
  fns = []
  document?.addEventListener("visibilitychange", ->
    for fn in fns
      fn(isDocumentVisible())
  )
  (fn) ->
    fns.push(fn)
)()

# Object helpers
# Not deep clone and not using JSON.stringify/JSON.parse because
# We want to keep functions
clone = (o) ->
  newO = {}
  for k, v of o
    newO[k] = v
  newO

# Caching
cacheFn = (func) ->
  data = {}
  ->
    key = ""
    for k in arguments
      key += k.toString() + ","
    result = data[key]
    unless result
      data[key] = result = func.apply(this, arguments)
    result

# Make a function accept array or single objects for the first argument
makeArrayFn = (fn) ->
  (el) ->
    if el instanceof Array or el instanceof NodeList or el instanceof HTMLCollection
      res = for i in [0...el.length]
        args = Array.prototype.slice.call(arguments, 1)
        args.splice(0, 0, el[i])
        fn.apply(this, args)
      return res
    fn.apply(this, arguments)

# Properties Helpers
applyDefaults = (options, defaults) ->
  for k, v of defaults
    options[k] ?= v

applyFrame = (el, properties) ->
  if(el.style?)
    applyProperties(el, properties)
  else
    for k, v of properties
      el[k] = v.format()

applyProperties = (el, properties) ->
  properties = parseProperties(properties)
  transforms = []
  isSVG = isSVGElement(el)
  for k, v of properties
    if transformProperties.contains(k)
      transforms.push([k, v])
    else
      if v.format?
        v = v.format()
      else
        v = "#{v}#{unitForProperty(k, v)}"
      if isSVG && svgProperties.contains(k)
        el.setAttribute(k, v)
      else
        el.style[propertyWithPrefix(k)] = v

  if transforms.length > 0
    if isSVG
      matrix = new Matrix2D()
      matrix.applyProperties(transforms)
      el.setAttribute("transform", matrix.decompose().format())
    else
      v = (transforms.map (transform) ->
        transformValueForProperty(transform[0], transform[1])
      ).join(" ")
      el.style[propertyWithPrefix("transform")] = v

isSVGElement = (el) ->
  if SVGElement? and SVGSVGElement?
    el instanceof SVGElement && !(el instanceof SVGSVGElement)
  else
    dynamics.tests?.isSVG?(el) ? false

# Math
roundf = (v, decimal) ->
  d = Math.pow(10, decimal)
  return Math.round(v * d) / d

# Set
class Set
  constructor: (array) ->
    @obj = {}
    for v in array
      @obj[v] = 1

  contains: (v) ->
    return @obj[v] == 1

# String Helpers
toDashed = (str) ->
  return str.replace(/([A-Z])/g, ($1) -> "-" + $1.toLowerCase())

# CSS Helpers
pxProperties = new Set('marginTop,marginLeft,marginBottom,marginRight,paddingTop,paddingLeft,paddingBottom,paddingRight,top,left,bottom,right,translateX,translateY,translateZ,perspectiveX,perspectiveY,perspectiveZ,width,height,maxWidth,maxHeight,minWidth,minHeight,borderRadius'.split(','))
degProperties = new Set('rotate,rotateX,rotateY,rotateZ,skew,skewX,skewY,skewZ'.split(','))
transformProperties = new Set('translate,translateX,translateY,translateZ,scale,scaleX,scaleY,scaleZ,rotate,rotateX,rotateY,rotateZ,rotateC,rotateCX,rotateCY,skew,skewX,skewY,skewZ,perspective'.split(','))
svgProperties = new Set('accent-height,ascent,azimuth,baseFrequency,baseline-shift,bias,cx,cy,d,diffuseConstant,divisor,dx,dy,elevation,filterRes,fx,fy,gradientTransform,height,k1,k2,k3,k4,kernelMatrix,kernelUnitLength,letter-spacing,limitingConeAngle,markerHeight,markerWidth,numOctaves,order,overline-position,overline-thickness,pathLength,points,pointsAtX,pointsAtY,pointsAtZ,r,radius,rx,ry,seed,specularConstant,specularExponent,stdDeviation,stop-color,stop-opacity,strikethrough-position,strikethrough-thickness,surfaceScale,target,targetX,targetY,transform,underline-position,underline-thickness,viewBox,width,x,x1,x2,y,y1,y2,z'.split(','))

unitForProperty = (k, v) ->
  return '' unless typeof v == 'number'
  if pxProperties.contains(k)
    return 'px'
  else if degProperties.contains(k)
    return 'deg'
  ''

transformValueForProperty = (k, v) ->
  match = "#{v}".match(/^([0-9.-]*)([^0-9]*)$/)
  if match?
    v = match[1]
    unit = match[2]
  else
    v = parseFloat(v)

  v = roundf(parseFloat(v), 10)

  if !unit? or unit == ""
    unit = unitForProperty(k, v)

  "#{k}(#{v}#{unit})"

parseProperties = (properties) ->
  parsed = {}
  for property, value of properties
    if transformProperties.contains(property)
      match = property.match(/(translate|rotateC|rotate|skew|scale|perspective)(X|Y|Z|)/)
      if match and match[2].length > 0
        parsed[property] = value
      else
        for axis in ['X', 'Y', 'Z']
          parsed[match[1] + axis] = value
    else
      parsed[property] = value
  parsed

defaultValueForKey = (key) ->
  v = if key == 'opacity' then 1 else 0
  "#{v}#{unitForProperty(key, v)}"

getCurrentProperties = (el, keys) ->
  properties = {}
  isSVG = isSVGElement(el)
  if el.style?
    style = window.getComputedStyle(el, null)
    for key in keys
      if transformProperties.contains(key)
        unless properties['transform']?
          if isSVG
            matrix = new Matrix2D(el.transform.baseVal.consolidate()?.matrix)
          else
            matrix = Matrix.fromTransform(style[propertyWithPrefix('transform')])
          properties['transform'] = matrix.decompose()
      else
        v = style[key]
        if !v? && svgProperties.contains(key)
          v = el.getAttribute(key)
        if v == "" or !v?
          v = defaultValueForKey(key)
        properties[key] = createInterpolable(v)
  else
    for key in keys
      properties[key] = createInterpolable(el[key])

  properties

# Interpolable
createInterpolable = (value) ->
  klasses = [InterpolableColor, InterpolableArray, InterpolableObject, InterpolableWithUnit]
  for klass in klasses
    interpolable = klass.create(value)
    return interpolable if interpolable?
  null

class InterpolableObject
  constructor: (obj) ->
    @obj = obj

  interpolate: (endInterpolable, t) =>
    start = @obj
    end = endInterpolable.obj
    newObj = {}
    for k, v of start
      if v.interpolate?
        newObj[k] = v.interpolate(end[k], t)
      else
        newObj[k] = v
    new InterpolableObject(newObj)

  format: =>
    @obj

  @create: (value) =>
    if value instanceof Object
      obj = {}
      for k, v of value
        obj[k] = createInterpolable(v)
      return new InterpolableObject(obj)
    null

class InterpolableWithUnit
  constructor: (value, @prefix, @suffix) ->
    @value = parseFloat(value)

  interpolate: (endInterpolable, t) =>
    start = @value
    end = endInterpolable.value
    new InterpolableWithUnit((end - start) * t + start, endInterpolable.prefix || @prefix, endInterpolable.suffix || @suffix)

  format: =>
    return roundf(@value, 5) if !@prefix? and !@suffix?
    @prefix + roundf(@value, 5) + @suffix

  @create: (value) =>
    return new InterpolableWithUnit(value) if typeof(value) != "string"
    match = ("#{value}").match("([^0-9.+-]*)([0-9.+-]+)([^0-9.+-]*)")
    if match?
      return new InterpolableWithUnit(match[2], match[1], match[3])
    null

class InterpolableArray
  constructor: (@values, @sep) ->

  interpolate: (endInterpolable, t) =>
    start = @values
    end = endInterpolable.values
    newValues = []
    for i in [0...Math.min(start.length, end.length)]
      if start[i].interpolate?
        newValues.push(start[i].interpolate(end[i], t))
      else
        newValues.push(start[i])
    new InterpolableArray(newValues, @sep)

  format: =>
    values = (@values.map (val) ->
      if val.format?
        val.format()
      else
        val
    )
    if @sep?
      values.join(@sep)
    else
      values

  @createFromArray: (arr, sep) =>
    values = arr.map (val) ->
      createInterpolable(val) || val
    values = values.filter (val) ->
      val?
    return new InterpolableArray(values, sep)

  @create: (value) =>
    return @createFromArray(value, null) if value instanceof Array
    return unless typeof(value) == "string"
    seps = [' ', ',', '|', ';', '/', ':']
    for sep in seps
      arr = value.split(sep)
      if arr.length > 1
        return @createFromArray(arr, sep)
    return null

class Color
  constructor: (@rgb={}, @format) ->

  @fromHex: (hex) ->
    hex3 = hex.match(/^#([a-f\d]{1})([a-f\d]{1})([a-f\d]{1})$/i)
    if hex3?
      hex = "##{hex3[1]}#{hex3[1]}#{hex3[2]}#{hex3[2]}#{hex3[3]}#{hex3[3]}"
    result = hex.match(/^#([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i)
    if result?
      return new Color({
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
        a: 1
      }, "hex")
    null

  @fromRgb: (rgb) ->
    match = rgb.match(/^rgba?\(([0-9.]*), ?([0-9.]*), ?([0-9.]*)(?:, ?([0-9.]*))?\)$/)
    if match?
      return new Color({
        r: parseFloat(match[1]),
        g: parseFloat(match[2]),
        b: parseFloat(match[3]),
        a: parseFloat(match[4] ? 1)
      }, if match[4]? then "rgba" else "rgb")
    null

  @componentToHex = (c) ->
    hex = c.toString(16);
    if hex.length == 1
      "0" + hex
    else
      hex

  toHex: =>
    "#" + Color.componentToHex(@rgb.r) + Color.componentToHex(@rgb.g) + Color.componentToHex(@rgb.b)

  toRgb: =>
    "rgb(#{@rgb.r}, #{@rgb.g}, #{@rgb.b})"

  toRgba: =>
    "rgba(#{@rgb.r}, #{@rgb.g}, #{@rgb.b}, #{@rgb.a})"

class InterpolableColor
  constructor: (@color) ->

  interpolate: (endInterpolable, t) =>
    start = @color
    end = endInterpolable.color
    rgb = {}
    for k in ['r', 'g', 'b']
      v = Math.round((end.rgb[k] - start.rgb[k]) * t + start.rgb[k])
      rgb[k] = Math.min(255, Math.max(0, v))
    k = "a"
    v = roundf((end.rgb[k] - start.rgb[k]) * t + start.rgb[k], 5)
    rgb[k] = Math.min(1, Math.max(0, v))
    new InterpolableColor(new Color(rgb, end.format))

  format: =>
    if @color.format == "hex"
      @color.toHex()
    else if @color.format == "rgb"
      @color.toRgb()
    else if @color.format == "rgba"
      @color.toRgba()

  @create: (value) =>
    return unless typeof(value) == "string"
    color = Color.fromHex(value) || Color.fromRgb(value)
    if color?
      return new InterpolableColor(color)
    null

# SVG Matrix2D
class DecomposedMatrix2D
  constructor: (@props) ->

  interpolate: (endMatrix, t) =>
    newProps = {}
    for k in ['translate', 'scale', 'rotate']
      newProps[k] = []
      for i in [0...@props[k].length]
        newProps[k][i] = (endMatrix.props[k][i] - @props[k][i]) * t + @props[k][i]
    for i in [1..2]
      newProps['rotate'][i] = endMatrix.props['rotate'][i]
    for k in ['skew']
      newProps[k] = (endMatrix.props[k] - @props[k]) * t + @props[k]

    new DecomposedMatrix2D(newProps)

  format: =>
    "translate(#{@props.translate.join(',')}) rotate(#{@props.rotate.join(',')})
     skewX(#{@props.skew}) scale(#{@props.scale.join(',')})"

  applyRotateCenter: (rotateC) =>
    m = baseSVG.createSVGMatrix()
    m = m.translate(rotateC[0], rotateC[1])
    m = m.rotate(@props.rotate[0])
    m = m.translate(-rotateC[0], -rotateC[1])
    m2d = new Matrix2D(m)

    negativeTranslate = m2d.decompose().props.translate
    for i in [0..1]
      @props.translate[i] -= negativeTranslate[i]

baseSVG = document?.createElementNS("http://www.w3.org/2000/svg", "svg")
class Matrix2D
  constructor: (@m) ->
    if !@m
      @m = baseSVG.createSVGMatrix()

  decompose: =>
    r0 = new Vector([@m.a, @m.b])
    r1 = new Vector([@m.c, @m.d])
    kx = r0.length()
    kz = r0.dot(r1)
    r0 = r0.normalize()
    ky = r1.combine(r0, 1, -kz).length()
    new DecomposedMatrix2D({
      translate: [@m.e, @m.f],
      rotate: [Math.atan2(@m.b, @m.a) * 180 / Math.PI, @rotateCX, @rotateCY],
      scale: [kx, ky],
      skew: kz / ky * 180 / Math.PI
    })

  applyProperties: (properties) =>
    hash = {}
    for props in properties
      hash[props[0]] = props[1]
    for k, v of hash
      if k == "translateX"
        @m = @m.translate(v, 0)
      else if k == "translateY"
        @m = @m.translate(0, v)
      else if k == "scaleX"
        @m = @m.scale(v, 1)
      else if k == "scaleY"
        @m = @m.scale(1, v)
      else if k == "rotateZ"
        @m = @m.rotate(v)
      else if k == "skewX"
        @m = @m.skewX(v)
      else if k == "skewY"
        @m = @m.skewY(v)

    @rotateCX = hash.rotateCX ? 0
    @rotateCY = hash.rotateCY ? 0

# Vector
# Some code has been ported from Sylvester.js https://github.com/jcoglan/sylvester
class Vector
  constructor: (@els) ->

  # Returns element i of the vector
  e: (i) =>
    return if (i < 1 || i > this.els.length) then null else this.els[i-1]

  # Returns the scalar product of the vector with the argument
  # Both vectors must have equal dimensionality
  dot: (vector) =>
    V = vector.els || vector
    product = 0
    n = this.els.length
    return null if n != V.length
    n += 1
    while --n
      product += this.els[n-1] * V[n-1]
    return product

  # Returns the vector product of the vector with the argument
  # Both vectors must have dimensionality 3
  cross: (vector) =>
    B = vector.els || vector
    return null if this.els.length != 3 || B.length != 3
    A = this.els
    return new Vector([
      (A[1] * B[2]) - (A[2] * B[1]),
      (A[2] * B[0]) - (A[0] * B[2]),
      (A[0] * B[1]) - (A[1] * B[0])
    ])

  length: =>
    a = 0
    for e in @els
      a += Math.pow(e, 2)
    Math.sqrt(a)

  normalize: =>
    length = @length()
    newElements = []
    for i, e of @els
      newElements[i] = e / length
    new Vector(newElements)

  combine: (b, ascl, bscl) =>
    result = []
    for i in [0...@els.length]
      result[i] = (ascl * @els[i]) + (bscl * b.els[i])
    new Vector(result)

# Matrix
class DecomposedMatrix
  interpolate: (decomposedB, t, only = null) =>
    decomposedA = @
    # New decomposedMatrix
    decomposed = new DecomposedMatrix

    # Linearly interpolate translate, scale, skew and perspective
    for k in [ 'translate', 'scale', 'skew', 'perspective' ]
      decomposed[k] = []
      for i in [0..decomposedA[k].length-1]
        if !only? or only.indexOf(k) > -1 or only.indexOf("#{k}#{['x','y','z'][i]}") > -1
          decomposed[k][i] = (decomposedB[k][i] - decomposedA[k][i]) * t + decomposedA[k][i]
        else
          decomposed[k][i] = decomposedA[k][i]

    if !only? or only.indexOf('rotate') != -1
      # Interpolate quaternion
      qa = decomposedA.quaternion
      qb = decomposedB.quaternion

      angle = qa[0] * qb[0] + qa[1] * qb[1] + qa[2] * qb[2] + qa[3] * qb[3]

      if angle < 0.0
        for i in [0..3]
          qa[i] = -qa[i]
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
        qb[0] = -qa[1]
        qb[1] = qa[0]
        qb[2] = -qa[3]
        qb[3] = qa[2]
        scale = Math.sin(piDouble * (.5 - t))
        invscale = Math.sin(piDouble * t)

      decomposed.quaternion = []
      for i in [0..3]
        decomposed.quaternion[i] = qa[i] * scale + qb[i] * invscale
    else
      decomposed.quaternion = decomposedA.quaternion

    return decomposed

  format: =>
    @toMatrix().toString()

  toMatrix: =>
    decomposedMatrix = @
    matrix = Matrix.I(4)

    # apply perspective
    for i in [0..3]
      matrix.els[i][3] = decomposedMatrix.perspective[i]

    # apply rotation
    quaternion = decomposedMatrix.quaternion
    x = quaternion[0]
    y = quaternion[1]
    z = quaternion[2]
    w = quaternion[3]

    # apply skew
    # temp is a identity 4x4 matrix initially
    skew = decomposedMatrix.skew
    match = [[1,0],[2,0],[2,1]]
    for i in [2..0]
      if skew[i]
        temp = Matrix.I(4)
        temp.els[match[i][0]][match[i][1]] = skew[i]
        matrix = matrix.multiply(temp)

    # Construct a composite rotation matrix from the quaternion values
    matrix = matrix.multiply(new Matrix([[
      1 - 2 * (y * y + z * z),
      2 * (x * y - z * w),
      2 * (x * z + y * w),
      0
    ], [
      2 * (x * y + z * w),
      1 - 2 * (x * x + z * z),
      2 * (y * z - x * w),
      0
    ], [
      2 * (x * z - y * w),
      2 * (y * z + x * w),
      1 - 2 * (x * x + y * y),
      0
    ], [ 0, 0, 0, 1 ]]))

    # apply scale and translation
    for i in [0..2]
      for j in [0..2]
        matrix.els[i][j] *= decomposedMatrix.scale[i]
      matrix.els[3][i] = decomposedMatrix.translate[i]

    matrix

# Some code has been ported from Sylvester.js https://github.com/jcoglan/sylvester
class Matrix
  constructor: (@els) ->

  # Returns element (i,j) of the matrix
  e: (i,j) =>
    return null if (i < 1 || i > this.els.length || j < 1 || j > this.els[0].length)
    this.els[i-1][j-1]

  # Returns a copy of the matrix
  dup: () =>
    return new Matrix(this.els)

  # Returns the result of multiplying the matrix from the right by the argument.
  # If the argument is a scalar then just multiply all the elements. If the argument is
  # a vector, a vector is returned, which saves you having to remember calling
  # col(1) on the result.
  multiply: (matrix) =>
    returnVector = if matrix.modulus then true else false
    M = matrix.els || matrix
    M = new Matrix(M).els if (typeof(M[0][0]) == 'undefined')
    ni = this.els.length
    ki = ni
    kj = M[0].length
    cols = this.els[0].length
    elements = []
    ni += 1
    while (--ni)
      i = ki - ni
      elements[i] = []
      nj = kj
      nj += 1
      while (--nj)
        j = kj - nj
        sum = 0
        nc = cols
        nc += 1
        while (--nc)
          c = cols - nc
          sum += this.els[i][c] * M[c][j]
        elements[i][j] = sum

    M = new Matrix(elements)
    return if returnVector then M.col(1) else M

  # Returns the transpose of the matrix
  transpose: =>
    rows = this.els.length
    cols = this.els[0].length
    elements = []
    ni = cols
    ni += 1
    while (--ni)
      i = cols - ni
      elements[i] = []
      nj = rows
      nj += 1
      while (--nj)
        j = rows - nj
        elements[i][j] = this.els[j][i]
    return new Matrix(elements)

  # Make the matrix upper (right) triangular by Gaussian elimination.
  # This method only adds multiples of rows to other rows. No rows are
  # scaled up or switched, and the determinant is preserved.
  toRightTriangular: =>
    M = this.dup()
    n = this.els.length
    k = n
    kp = this.els[0].length
    while (--n)
      i = k - n
      if (M.els[i][i] == 0)
        for j in [i + 1...k]
          if (M.els[j][i] != 0)
            els = []
            np = kp
            np += 1
            while (--np)
              p = kp - np
              els.push(M.els[i][p] + M.els[j][p])
            M.els[i] = els
            break
      if (M.els[i][i] != 0)
        for j in [i + 1...k]
          multiplier = M.els[j][i] / M.els[i][i]
          els = []
          np = kp
          np += 1
          while (--np)
            p = kp - np
            # Elements with column numbers up to an including the number
            # of the row that we're subtracting can safely be set straight to
            # zero, since that's the point of this routine and it avoids having
            # to loop over and correct rounding errors later
            els.push(if p <= i then 0 else M.els[j][p] - M.els[i][p] * multiplier)
          M.els[j] = els
    return M

  # Returns the result of attaching the given argument to the right-hand side of the matrix
  augment: (matrix) =>
    M = matrix.els || matrix
    M = new Matrix(M).els if (typeof(M[0][0]) == 'undefined')
    T = this.dup()
    cols = T.els[0].length
    ni = T.els.length
    ki = ni
    kj = M[0].length
    return null if (ni != M.length)
    ni += 1
    while (--ni)
      i = ki - ni
      nj = kj
      nj += 1
      while (--nj)
        j = kj - nj
        T.els[i][cols + j] = M[i][j]

    return T

  # Returns the inverse (if one exists) using Gauss-Jordan
  inverse: =>
    ni = this.els.length
    ki = ni
    M = this.augment(Matrix.I(ni)).toRightTriangular()
    kp = M.els[0].length
    inverse_elements = []
    # Matrix is non-singular so there will be no zeros on the diagonal
    # Cycle through rows from last to first
    ni += 1
    while (--ni)
      i = ni - 1
      # First, normalise diagonal elements to 1
      els = []
      np = kp
      inverse_elements[i] = []
      divisor = M.els[i][i]
      np += 1
      while (--np)
        p = kp - np
        new_element = M.els[i][p] / divisor
        els.push(new_element)
        # Shuffle of the current row of the right hand side into the results
        # array as it will not be modified by later runs through this loop
        if (p >= ki)
          inverse_elements[i].push(new_element)

      M.els[i] = els
      # Then, subtract this row from those above it to
      # give the identity matrix on the left hand side
      for j in [0...i]
        els = []
        np = kp
        np += 1
        while (--np)
          p = kp - np
          els.push(M.els[j][p] - M.els[i][p] * M.els[j][i])
        M.els[j] = els

    return new Matrix(inverse_elements)

  @I = (n) ->
    els = []
    k = n
    n += 1
    while --n
      i = k - n
      els[i] = []
      nj = k
      nj += 1
      while --nj
        j = k - nj
        els[i][j] = if (i == j) then 1 else 0

    new Matrix(els)

  decompose: =>
    matrix = @
    translate = []
    scale = []
    skew = []
    quaternion = []
    perspective = []

    # Deep copy
    els = []
    for i in [0..3]
      els[i] = []
      for j in [0..3]
        els[i][j] = matrix.els[i][j]

    if (els[3][3] == 0)
      return false

    # Normalize the matrix.
    for i in [0..3]
      for j in [0..3]
        els[i][j] /= els[3][3]

    # perspectiveMatrix is used to solve for perspective, but it also provides
    # an easy way to test for singularity of the upper 3x3 component.
    perspectiveMatrix = matrix.dup()

    for i in [0..2]
      perspectiveMatrix.els[i][3] = 0
    perspectiveMatrix.els[3][3] = 1

    # Don't do this anymore, it would return false for scale(0)..
    # if perspectiveMatrix.determinant() == 0
    #   return false

    # First, isolate perspective.
    if els[0][3] != 0 || els[1][3] != 0 || els[2][3] != 0
      # rightHandSide is the right hand side of the equation.
      rightHandSide = new Vector(els[0..3][3])

      # Solve the equation by inverting perspectiveMatrix and multiplying
      # rightHandSide by the inverse.
      inversePerspectiveMatrix = perspectiveMatrix.inverse()
      transposedInversePerspectiveMatrix = inversePerspectiveMatrix.transpose()
      perspective = transposedInversePerspectiveMatrix.multiply(rightHandSide).els

      # Clear the perspective partition
      for i in [0..2]
        els[i][3] = 0
      els[3][3] = 1
    else
      # No perspective.
      perspective = [0,0,0,1]

    # Next take care of translation
    for i in [0..2]
      translate[i] = els[3][i]
      els[3][i] = 0

    # Now get scale and shear. 'row' is a 3 element array of 3 component vectors
    row = []
    for i in [0..2]
      row[i] = new Vector(els[i][0..2])

    # Compute X scale factor and normalize first row.
    scale[0] = row[0].length()
    row[0] = row[0].normalize()

    # Compute XY shear factor and make 2nd row orthogonal to 1st.
    skew[0] = row[0].dot(row[1])
    row[1] = row[1].combine(row[0], 1.0, -skew[0])

    # Now, compute Y scale and normalize 2nd row.
    scale[1] = row[1].length()
    row[1] = row[1].normalize()
    skew[0] /= scale[1]

    # Compute XZ and YZ shears, orthogonalize 3rd row
    skew[1] = row[0].dot(row[2])
    row[2] = row[2].combine(row[0], 1.0, -skew[1])
    skew[2] = row[1].dot(row[2])
    row[2] = row[2].combine(row[1], 1.0, -skew[2])

    # Next, get Z scale and normalize 3rd row.
    scale[2] = row[2].length()
    row[2] = row[2].normalize()
    skew[1] /= scale[2]
    skew[2] /= scale[2]

    # At this point, the matrix (in rows) is orthonormal.
    # Check for a coordinate system flip.  If the determinant
    # is -1, then negate the matrix and the scaling factors.
    pdum3 = row[1].cross(row[2])
    if row[0].dot(pdum3) < 0
      for i in [0..2]
        scale[i] *= -1
        for j in [0..2]
          row[i].els[j] *= -1

    # Get element at row
    rowElement = (index, elementIndex) ->
      row[index].els[elementIndex]

    # Euler angles
    rotate = []
    rotate[1] = Math.asin(-rowElement(0, 2))
    if Math.cos(rotate[1]) != 0
      rotate[0] = Math.atan2(rowElement(1, 2), rowElement(2, 2))
      rotate[2] = Math.atan2(rowElement(0, 1), rowElement(0, 0))
    else
      rotate[0] = Math.atan2(-rowElement(2, 0), rowElement(1, 1))
      rotate[1] = 0

    # Now, get the rotations out
    t = rowElement(0, 0) + rowElement(1, 1) + rowElement(2, 2) + 1.0
    if t > 1e-4
      s = 0.5 / Math.sqrt(t)
      w = 0.25 / s
      x = (rowElement(2, 1) - rowElement(1, 2)) * s
      y = (rowElement(0, 2) - rowElement(2, 0)) * s
      z = (rowElement(1, 0) - rowElement(0, 1)) * s
    else if (rowElement(0, 0) > rowElement(1, 1)) && (rowElement(0, 0) > rowElement(2, 2))
      s = Math.sqrt(1.0 + rowElement(0, 0) - rowElement(1, 1) - rowElement(2, 2)) * 2.0
      x = 0.25 * s
      y = (rowElement(0, 1) + rowElement(1, 0)) / s
      z = (rowElement(0, 2) + rowElement(2, 0)) / s
      w = (rowElement(2, 1) - rowElement(1, 2)) / s
    else if rowElement(1, 1) > rowElement(2, 2)
      s = Math.sqrt(1.0 + rowElement(1, 1) - rowElement(0, 0) - rowElement(2, 2)) * 2.0
      x = (rowElement(0, 1) + rowElement(1, 0)) / s
      y = 0.25 * s
      z = (rowElement(1, 2) + rowElement(2, 1)) / s
      w = (rowElement(0, 2) - rowElement(2, 0)) / s
    else
      s = Math.sqrt(1.0 + rowElement(2, 2) - rowElement(0, 0) - rowElement(1, 1)) * 2.0
      x = (rowElement(0, 2) + rowElement(2, 0)) / s
      y = (rowElement(1, 2) + rowElement(2, 1)) / s
      z = 0.25 * s
      w = (rowElement(1, 0) - rowElement(0, 1)) / s

    quaternion = [x, y, z, w]

    result = new DecomposedMatrix
    result.translate = translate
    result.scale = scale
    result.skew = skew
    result.quaternion = quaternion
    result.perspective = perspective
    result.rotate = rotate

    for typeKey, type of result
      for k, v of type
        type[k] = 0 if isNaN(v)

    result

  toString: =>
    str = 'matrix3d('
    for i in [0..3]
      for j in [0..3]
        str += roundf(@els[i][j], 10)
        str += ',' unless i == 3 and j == 3
    str += ')'
    str

  @matrixForTransform: cacheFn (transform) ->
    matrixEl = document.createElement('div')
    matrixEl.style.position = 'absolute'
    matrixEl.style.visibility = 'hidden'
    matrixEl.style[propertyWithPrefix("transform")] = transform
    document.body.appendChild(matrixEl)
    style = window.getComputedStyle(matrixEl, null)
    result = style.transform ? style[propertyWithPrefix("transform")] ? dynamics.tests?.matrixForTransform(transform)
    document.body.removeChild(matrixEl)
    result

  @fromTransform: (transform) ->
    match = transform?.match /matrix3?d?\(([-0-9,e \.]*)\)/
    if match
      digits = match[1].split(',')
      digits = digits.map(parseFloat)
      if digits.length == 6
        # format: matrix(a, c, b, d, tx, ty)
        elements = [digits[0], digits[1], 0, 0, digits[2], digits[3], 0, 0, 0, 0, 1, 0, digits[4], digits[5], 0, 1]
      else
        elements = digits
    else
      elements = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]

    matrixElements = []
    for i in [0..3]
      matrixElements.push(elements.slice(i * 4,i * 4 + 4))
    new Matrix(matrixElements)

# Support
prefixFor = cacheFn (property) ->
  return '' if document.body.style[property] != undefined
  propArray = property.split('-')
  propertyName = ""
  for prop in propArray
    propertyName += prop.substring(0, 1).toUpperCase() + prop.substring(1)
  for prefix in [ "Webkit", "Moz", "ms" ]
    k = prefix + propertyName
    if document.body.style[k] != undefined
      return prefix
  ''
propertyWithPrefix = cacheFn (property) ->
  prefix = prefixFor(property)
  return "#{prefix}#{property.substring(0, 1).toUpperCase() + property.substring(1)}" if prefix == 'Moz'
  return "-#{prefix.toLowerCase()}-#{toDashed(property)}" if prefix != ''
  toDashed(property)

# Run loop
rAF = window?.requestAnimationFrame
animations = []
animationsTimeouts = []
slow = false
slowRatio = 1

window?.addEventListener 'keyup', (e) ->
  # Enable slow animations with ctrl+shift+D
  if e.keyCode == 68 and e.shiftKey and e.ctrlKey
    dynamics.toggleSlow()

if !rAF?
  lastTime = 0
  rAF = (callback) ->
    currTime = Date.now()
    timeToCall = Math.max(0, 16 - (currTime - lastTime))
    id = window.setTimeout ->
      callback(currTime + timeToCall)
    , timeToCall
    lastTime = currTime + timeToCall
    id

runLoopRunning = false
runLoopPaused = false
startRunLoop = ->
  unless runLoopRunning
    runLoopRunning = true
    rAF(runLoopTick)

runLoopTick = (t) ->
  if runLoopPaused
    rAF(runLoopTick)
    return

  # Animations
  toRemoveAnimations = []
  for animation in animations
    toRemoveAnimations.push(animation) unless animationTick(t, animation)
  animations = animations.filter (animation) ->
    toRemoveAnimations.indexOf(animation) == -1

  if animations.length == 0
    runLoopRunning = false
  else
    rAF(runLoopTick)

animationTick = (t, animation) ->
  animation.tStart ?= t
  tt = (t - animation.tStart) / animation.options.duration
  y = animation.curve(tt)

  properties = {}
  if tt >= 1
    if animation.curve.returnsToSelf
      properties = animation.properties.start
    else
      properties = animation.properties.end
  else
    for key, property of animation.properties.start
      properties[key] = interpolate(property, animation.properties.end[key], y)

  applyFrame(animation.el, properties)

  animation.options.change?(animation.el)
  if tt >= 1
    animation.options.complete?(animation.el)

  return tt < 1

interpolate = (start, end, y) ->
  if start? and start.interpolate?
    return start.interpolate(end, y)
  null

# Animations
startAnimation = (el, properties, options, timeoutId) ->
  if timeoutId?
    animationsTimeouts = animationsTimeouts.filter (timeout) ->
      return timeout.id != timeoutId

  dynamics.stop(el, { timeout: false })
  if !options.animated
    dynamics.css(el, properties)
    options.complete?(@)
    return
  properties = parseProperties(properties)
  startProperties = getCurrentProperties(el, Object.keys(properties))
  endProperties = {}
  transforms = []
  for k, v of properties
    if el.style? and transformProperties.contains(k)
      transforms.push([k, v])
    else
      endProperties[k] = createInterpolable(v)
      if endProperties[k] instanceof InterpolableWithUnit && el.style?
        # We don't have the unit, we'll get the default one
        endProperties[k].prefix = ''
        endProperties[k].suffix ?= unitForProperty(k, 0)

  if transforms.length > 0
    isSVG = isSVGElement(el)
    if isSVG
      matrix = new Matrix2D()
      matrix.applyProperties(transforms)
    else
      v = (transforms.map (transform) ->
        transformValueForProperty(transform[0], transform[1])
      ).join(" ")
      matrix = Matrix.fromTransform(Matrix.matrixForTransform(v))
    endProperties['transform'] = matrix.decompose()

    if isSVG
      startProperties.transform.applyRotateCenter(
        [endProperties.transform.props.rotate[1], endProperties.transform.props.rotate[2]]
      )

  animations.push({
    el: el,
    properties: {
      start: startProperties,
      end: endProperties
    },
    options: options,
    curve: options.type.call(options.type, options)
  })
  startRunLoop()

# Timeouts
timeouts = []
timeoutLastId = 0

setRealTimeout = (timeout) ->
  return unless isDocumentVisible()
  timeout.realTimeoutId = setTimeout(->
    timeout.fn()
    cancelTimeout(timeout.id)
  , timeout.delay)

addTimeout = (fn, delay) ->
  timeoutLastId += 1
  timeout = {
    id: timeoutLastId,
    tStart: Date.now(),
    fn: fn,
    delay: delay,
    originalDelay: delay
  }
  setRealTimeout(timeout)
  timeouts.push(timeout)
  timeoutLastId

cancelTimeout = (id) ->
  timeouts = timeouts.filter (timeout) ->
    if timeout.id == id
      clearTimeout(timeout.realTimeoutId)
    timeout.id != id

leftDelayForTimeout = (time, timeout) ->
  if time?
    consumedDelay = time - timeout.tStart
    timeout.originalDelay - consumedDelay
  else
    timeout.originalDelay

window?.addEventListener('unload', ->
  # This is a hack for Safari to fix the case where the user does back/forward
  # between this page. If this event is not listened to, it seems like safari is keeping
  # the javascript state but this cause problems with setTimeout/rAF
)

# Visibility change
# Need to pause rAF and timeouts
timeBeforeVisibilityChange = null
observeVisibilityChange (visible) ->
  runLoopPaused = !visible
  if !visible
    timeBeforeVisibilityChange = Date.now()

    for timeout in timeouts
      clearTimeout(timeout.realTimeoutId)
  else
    if runLoopRunning
      difference = Date.now() - timeBeforeVisibilityChange
      for animation in animations
        animation.tStart += difference if animation.tStart?

    for timeout in timeouts
      timeout.delay = leftDelayForTimeout(timeBeforeVisibilityChange, timeout)
      setRealTimeout(timeout)

    timeBeforeVisibilityChange = null

# Module
dynamics = {}

# Curves
dynamics.linear = ->
  (t) ->
    t

dynamics.spring = (options={}) ->
  applyDefaults(options, dynamics.spring.defaults)

  frequency = Math.max(1, options.frequency / 20)
  friction = Math.pow(20, options.friction / 100)
  s = options.anticipationSize / 1000
  decal = Math.max(0, s)

  # In case of anticipation
  A1 = (t) ->
    M = 0.8

    x0 = (s / (1 - s))
    x1 = 0

    b = (x0 - (M * x1)) / (x0 - x1)
    a = (M - b) / x0

    (a * t * options.anticipationStrength / 100) + b

  # Normal curve
  A2 = (t) ->
    Math.pow(friction / 10,-t) * (1 - t)

  (t) ->
    frictionT = (t / (1 - s)) - (s / (1 - s))

    if t < s
      yS = (s / (1 - s)) - (s / (1 - s))
      y0 = (0 / (1 - s)) - (s / (1 - s))
      b = Math.acos(1 / A1(yS))
      a = (Math.acos(1 / A1(y0)) - b) / (frequency * (-s))
      A = A1
    else
      A = A2

      b = 0
      a = 1

    At = A(frictionT)

    angle = frequency * (t - s) * a + b
    1 - (At * Math.cos(angle))

dynamics.bounce = (options={}) ->
  applyDefaults(options, dynamics.bounce.defaults)

  frequency = Math.max(1, options.frequency / 20)
  friction = Math.pow(20, options.friction / 100)
  A = (t) ->
    Math.pow(friction / 10,-t) * (1 - t)

  fn = (t) ->

    b = -3.14/2
    a = 1

    At = A(t)

    angle = frequency * t * a + b
    (At * Math.cos(angle))
  fn.returnsToSelf = true
  fn

dynamics.gravity = (options={}) ->
  applyDefaults(options, dynamics.gravity.defaults)

  bounciness = Math.min((options.bounciness / 1250), 0.8)
  elasticity = options.elasticity / 1000
  gravity = 100

  curves = []
  L = do ->
    b = Math.sqrt(2 / gravity)
    curve = { a: -b, b: b, H: 1 }
    if options.returnsToSelf
      curve.a = 0
      curve.b = curve.b * 2
    while curve.H > 0.001
      L = curve.b - curve.a
      curve = { a: curve.b, b: curve.b + L * bounciness, H: curve.H * bounciness * bounciness }
    curve.b

  getPointInCurve = (a, b, H, t) ->
    L = b - a
    t2 = (2 / L) * (t) - 1 - (a * 2 / L)
    c = t2 * t2 * H - H + 1
    c = 1 - c if options.returnsToSelf
    c

  # Create curves
  do ->
    b = Math.sqrt(2 / (gravity * L * L))
    curve = { a: -b, b: b, H: 1 }
    if options.returnsToSelf
      curve.a = 0
      curve.b = curve.b * 2
    curves.push curve
    L2 = L
    while curve.b < 1 and curve.H > 0.001
      L2 = curve.b - curve.a
      curve = { a: curve.b, b: curve.b + L2 * bounciness, H: curve.H * elasticity }
      curves.push curve

  fn = (t) ->
    i = 0
    curve = curves[i]
    while(!(t >= curve.a and t <= curve.b))
      i += 1
      curve = curves[i]
      break unless curve

    if !curve
      v = if options.returnsToSelf then 0 else 1
    else
      v = getPointInCurve(curve.a, curve.b, curve.H, t)
    v
  fn.returnsToSelf = options.returnsToSelf
  fn

dynamics.forceWithGravity = (options={}) ->
  applyDefaults(options, dynamics.forceWithGravity.defaults)
  options.returnsToSelf = true
  dynamics.gravity(options)

dynamics.bezier = do ->
  Bezier_ = (t, p0, p1, p2, p3) ->
    (Math.pow(1 - t, 3) * p0) + (3 * Math.pow(1 - t, 2) * t * p1) + (3 * (1 - t) * Math.pow(t, 2) * p2) + Math.pow(t, 3) * p3

  Bezier = (t, p0, p1, p2, p3) ->
    {
      x: Bezier_(t, p0.x, p1.x, p2.x, p3.x),
      y: Bezier_(t, p0.y, p1.y, p2.y, p3.y)
    }

  yForX = (xTarget, Bs, returnsToSelf) ->
    # Find the right Bezier curve first
    B = null
    for aB in Bs
      if xTarget >= aB(0).x and xTarget <= aB(1).x
        B = aB
      break if B != null

    unless B
      if returnsToSelf
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
    return B(percent).y

  # Actual bezier function
  (options={}) ->
    points = options.points

    # Init different curves
    Bs = do ->
      Bs = []
      for i of points
        k = parseInt(i)
        break if k >= points.length - 1
        ((pointA, pointB) ->
          B2 = (t) ->
            Bezier(t, pointA, pointA.cp[pointA.cp.length - 1], pointB.cp[0], pointB)
          Bs.push(B2)
        )(points[k], points[k + 1])
      Bs

    fn = (t) ->
      if t == 0
        return 0
      else if t == 1
        return 1
      else
        yForX(t, Bs, @returnsToSelf)
    fn.returnsToSelf = points[points.length - 1].y == 0
    fn

dynamics.easeInOut = (options={}) ->
  friction = options.friction ? dynamics.easeInOut.defaults.friction
  dynamics.bezier(points: [
    { x:0, y:0, cp:[{ x:0.92 - (friction / 1000), y:0 }] },
    { x:1, y:1, cp:[{ x:0.08 + (friction / 1000), y:1 }] }
  ])

dynamics.easeIn = (options={}) ->
  friction = options.friction ? dynamics.easeIn.defaults.friction
  dynamics.bezier(points: [
    { x:0, y:0, cp:[{ x:0.92 - (friction / 1000), y:0 }] },
    { x:1, y:1, cp:[{ x:1, y:1 }] }
  ])

dynamics.easeOut = (options={}) ->
  friction = options.friction ? dynamics.easeOut.defaults.friction
  dynamics.bezier(points: [
    { x:0, y:0, cp:[{ x:0, y:0 }] },
    { x:1, y:1, cp:[{ x:0.08 + (friction / 1000), y:1 }] }
  ])

# Default options
dynamics.spring.defaults =
  frequency: 300
  friction: 200
  anticipationSize: 0
  anticipationStrength: 0
dynamics.bounce.defaults =
  frequency: 300
  friction: 200
dynamics.forceWithGravity.defaults = dynamics.gravity.defaults =
  bounciness: 400
  elasticity: 200
dynamics.easeInOut.defaults = dynamics.easeIn.defaults = dynamics.easeOut.defaults =
  friction: 500

# CSS
dynamics.css = makeArrayFn (el, properties) ->
  applyProperties(el, properties, true)

# Animation
dynamics.animate = makeArrayFn (el, properties, options={}) ->
  options = clone(options)
  applyDefaults(options, {
    type: dynamics.easeInOut,
    duration: 1000,
    delay: 0,
    animated: true
  })
  options.duration = Math.max(0, options.duration * slowRatio)
  options.delay = Math.max(0, options.delay)

  if options.delay == 0
    startAnimation(el, properties, options)
  else
    id = dynamics.setTimeout ->
      startAnimation(el, properties, options, id)
    , options.delay
    animationsTimeouts.push({
      id: id,
      el: el
    })

dynamics.stop = makeArrayFn (el, options={}) ->
  options.timeout ?= true
  if options.timeout
    # Clear timeouts too
    animationsTimeouts = animationsTimeouts.filter (timeout) ->
      if timeout.el == el and (!options.filter? or options.filter(timeout))
        dynamics.clearTimeout(timeout.id)
        return false
      true

  animations = animations.filter (animation) ->
    animation.el != el

dynamics.setTimeout = (fn, delay) ->
  addTimeout(fn, delay * slowRatio)

dynamics.clearTimeout = (id) ->
  cancelTimeout(id)

dynamics.toggleSlow = ->
  slow = !slow
  if slow
    slowRatio = 3
  else
    slowRatio = 1
  console?.log?("dynamics.js: slow animations #{if slow then "enabled" else "disabled"}")

# CommonJS
if typeof module == "object" and typeof module.exports == "object"
  module.exports = dynamics
# AMD
else if typeof define == "function"
  define('dynamics', -> dynamics)
# Global
else
  window.dynamics = dynamics

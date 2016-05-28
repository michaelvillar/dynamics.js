# Dynamics.js
Dynamics.js is a JavaScript library to create physics-based animations

To see some demos, check out [dynamicsjs.com](http://dynamicsjs.com).

## Usage
Download:
- [GitHub releases](https://github.com/michaelvillar/dynamics.js/releases)
- [npm](https://www.npmjs.com/package/dynamics.js): `npm install dynamics.js`
- bower: `bower install dynamics.js`

Include `dynamics.js` into your page:
```html
<script src="dynamics.js"></script>
```
You can animate CSS properties of any DOM element.
```javascript
var el = document.getElementById("logo")
dynamics.animate(el, {
  translateX: 350,
  scale: 2,
  opacity: 0.5
}, {
  type: dynamics.spring,
  frequency: 200,
  friction: 200,
  duration: 1500
})
```

You also can animate SVG properties.
```javascript
var path = document.querySelector("path")
dynamics.animate(path, {
  d: "M0,0 L0,100 L100,50 L0,0 Z",
  fill: "#FF0000",
  rotateZ: 45,
  // rotateCX and rotateCY are the center of the rotation
  rotateCX: 100,
  rotateCY: 100
}, {
  friction: 800
})
```

And any JavaScript object.
```javascript
var o = {
  number: 10,
  color: "#FFFFFF",
  string: "10deg",
  array: [ 1, 10 ]
}
dynamics.animate(o, {
  number: 20,
  color: "#000000",
  string: "90deg",
  array: [-9, 99 ]
})
```

## Reference
### dynamics.animate(el, properties, options)
Animates an element to the properties with the animation options.
- `el` is a DOM element, a JavaScript object or an Array of elements
- `properties` is an object of the properties/values you want to animate
- `options` is an object representing the animation
  - `type` is the [animation type](#dynamics-and-properties): `dynamics.spring`, `dynamics.easeInOut`,... (default: `dynamics.easeInOut`)
  - `frequency`, `friction`, `bounciness`,... are specific to the animation type you are using
  - `duration` is in milliseconds (default: `1000`)
  - `delay` is in milliseconds (default: `0`)
  - `complete` (optional) is the completion callback
  - `change` (optional) is called at every change. Two arguments are passed to the function. `function(el, progress)`
    - `el` is the element it's animating
    - `progress` is the progress of the animation between 0 and 1

### dynamics.stop(el)
Stops the animation applied on the element

### dynamics.css(el, properties)
This is applying the CSS properties to your element with the correct browser prefixes.
- `el` is a DOM element
- `properties` is an object of the CSS properties

### dynamics.setTimeout(fn, delay)
Dynamics.js has its own `setTimeout`. The reason is that `requestAnimationFrame` and `setTimeout` have different behaviors. In most browsers, `requestAnimationFrame` will not run in a background tab while `setTimeout` will. This can cause a lot of problems while using `setTimeout` along your animations. I suggest you use Dynamics's `setTimeout` and `clearTimeout` to handle these scenarios.
- `fn` is the callback
- `delay` is in milliseconds

Returns a unique id

### dynamics.clearTimeout(id)
Clears a timeout that was defined earlier
- `id` is the timeout id

### dynamics.toggleSlow()
Toggle a debug mode to slow down every animations and timeouts.
This is useful for development mode to tweak your animation.
This can be activated using `Shift-Control-D` in the browser.

## Dynamics and properties
### dynamics.spring
- `frequency` default is 300
- `friction` default is 200
- `anticipationSize` (optional)
- `anticipationStrength` (optional)

### dynamics.bounce
- `frequency` default is 300
- `friction` default is 200

### dynamics.forceWithGravity and dynamics.gravity
- `bounciness` default is 400
- `elasticity` default is 200

### dynamics.easeInOut, dynamics.easeIn and dynamics.easeOut
- `friction` default is 500

### dynamics.linear
No properties

### dynamics.bezier
- `points` array of points and control points

The easiest way to output this kind of array is to use the [curve creator](http://dynamicsjs.com). Here is an example:
```javascript
[{"x":0,"y":0,"cp":[{"x":0.2,"y":0}]},
 {"x":0.5,"y":-0.4,"cp":[{"x":0.4,"y":-0.4},{"x":0.8,"y":-0.4}]},
 {"x":1,"y":1,"cp":[{"x":0.8,"y":1}]}]
```

## Contributing
Compile: `npm run build` or `npm run build:watch`

Run tests: `npm test`

## Browser Support
Working on
- Safari 7+
- Firefox 35+
- Chrome 34+
- IE10+

## Sylvester
Some code from Sylvester.js has been used (part of Vector and Matrix).

## License
The MIT License (MIT)

Copyright (c) 2015 Michael Villar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

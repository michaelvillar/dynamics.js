# Dynamics.js
Dynamics.js is a Javascript library to create physics-related CSS animations

To see some demos, checkout [Dynamics.js's website](http://michaelvillar.github.io/dynamics.js).

## Usage
Dynamics depends on [Sylvester](https://github.com/jcoglan/sylvester). You'll then include `dynamics.js`.
```
<script src="lib/sylvester.js" type="text/javascript"></script>  
<script src="lib/dynamics.js" type="text/javascript"></script>  
```
Create a `Dynamics.Animation` to animate properties of an element.
```
var animation = new Dynamics.Animation(element, properties, options);
```
- `element` is a DOM element
- `properties` is an object of the CSS properties
- `options` is an object representing the animation
  - `type` is the animation type: `Dynamics.Types.Spring`, `Dynamics.Types.Gravity`,...
  - `frequency`, `friction`, `gravity`,... are specific to the animation type you are using
  - `duration` is the duration in milliseconds
  - `complete` (optional) is the completion callback
  - `debugName` (optional) is used to debug your curve using the curve creator 

You can then start the animation:
```
animation.start();
```

##### Example:
```
var element = document.getElementById("logo");
var animation = new Dynamics.Animation(element, {
  transform: "translateX(350px) scale(2)",
  opacity: 1
}, {
  type: Dynamics.Types.Spring,
  frequency: 15,
  friction: 200,
  duration: 1000
});
animation.start();
```

You can easily apply css properties to an element using `Dynamics.css(element, properties)`. This is helpful to apply correct prefixes to some properties like `-webkit-transform`
##### Example:
```
Dynamics.css(element, {
  transform: 'scale(.5)'
})
```

### Using the curve creator in your app
You need to include `debug.js` in development.
```
<script src="lib/debug.js" type="text/javascript"></script>  
```
Then, you can just pass the property `debugName` to your animation properties.
```
var animation = new Dynamics.Animation(element, properties, {
  [...]
  debugName: 'animationName'
});
```
When the animation is started, the curve creator will open allowing you to test your curve in realtime.

## Contributing
To compile: `coffee -w -c -o js/ src/*.coffee`

## Browser Support
Tested on
- Chrome 33
- Safari 7.0.2
- Firefox 27
- IE10 and IE11

Broken on
- IE9 and below

## License

The MIT License (MIT)

Copyright (c) 2014 Michael Villar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

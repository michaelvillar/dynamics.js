# Dynamics.js
Dynamics.js is a Javascript library to create physics-related CSS animations

To see some demos, checkout [Dynamics.js's website](http://michaelvillar.github.io/dynamics.js).

## Basic usage
Files to include are `dynamics.js` and [Sylvester](https://github.com/jcoglan/sylvester)
```
<script src="js/sylvester.js" type="text/javascript"></script>  
<script src="js/dynamics.js" type="text/javascript"></script>  
```

### Animation
Animate properties of an element using a Spring dynamic:
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

### CSS
Apply css properties to an element. This is helpful to apply correct prefixes to some properties like `-webkit-transform`:
```
Dynamics.css(element, {
  transform: "translateX(350px) scale(2)",
  opacity: 1
})
```

### Using the curve creator in your app
You need to include `debug.js` in development.
```
<script src="js/debug.js" type="text/javascript"></script>  
```
Then, you can just pass the property `debugName` to your animation properties.
```
var animation = new Dynamics.Animation(element, {
  [css properties]
}, {
  [animation properties]
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

# Dynamics.js
Dynamics.js is a Javascript library to create physics-related CSS animations

Use the curve creator to test capabilities: http://michaelvillar.github.io/dynamics.js

## Demo
- http://michaelvillar.github.io/dynamics.js/example.html
- http://michaelvillar.github.io/dynamics.js/profile.html

## Usage
### Animation
Create animation with a DOMElement, css properties and animation properties.
```
new Dynamics.Animation(element, {
  transform: "translateX(350px) scale(2)",
  opacity: 1
}, {
  type: Dynamics.Types.Spring,
  frequency: 15,
  friction: 200,
  duration: 1000
}).start();
```

### CSS
Apply css properties to an DOMElement
```
Dynamics.css(element, {
  transform: "translateX(350px) scale(2)",
  opacity: 1
})
```

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

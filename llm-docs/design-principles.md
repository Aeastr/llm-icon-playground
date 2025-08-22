# Design Principles

## Layer Order (Critical)
In layers array - TOP TO BOTTOM:
- `layers[0]` = front (visible on top)  
- `layers[1]` = middle
- `layers[2]` = back

Example:
```json
"layers": [
  {"name": "star", "image-name": "star.svg"},    // front
  {"name": "circle", "image-name": "circle.svg"} // back  
]
```

## Guidelines
- Use 2-3 layers typically
- Scale: 0.5-1.5 for main elements, 0.1-0.3 for details
- Use positioning, effects, and depth creatively
- Consider light/dark mode specializations
- Icons viewed at multiple sizes - keep readable
# Layer Properties

## Basic Properties

### Image Reference
```json
"image-name": "filename.png"
```
References a PNG file in the `Assets/` directory.

### Layer Identification
```json
"name": "LayerName"
```
Human-readable identifier for the layer.

### Visibility
```json
"hidden": false
```
Boolean controlling layer visibility. Can be overridden with specializations.

## Positioning

### Position Object
```json
"position": {
  "scale": 1.0,
  "translation-in-points": [x, y]
}
```

- `scale`: Floating point scale multiplier (1.0 = original size)
- `translation-in-points`: Array of [x, y] coordinates in points

## Fill Properties

Layers can override or specify their own fill, independent of the root fill.

### Automatic Gradient
```json
"fill": {
  "automatic-gradient": "extended-srgb:0.00000,0.53333,1.00000,1.00000"
}
```

### Solid Color
```json
"fill": {
  "solid": "extended-srgb:0.00000,0.53333,1.00000,1.00000"
}
```

## Visual Effects

### Opacity
Layers support opacity through specializations:
```json
"opacity-specializations": [
  {
    "value": 1.0
  },
  {
    "appearance": "dark",
    "value": 0.5
  }
]
```

### Blend Modes
```json
"blend-mode-specializations": [
  {
    "appearance": "dark",
    "value": "darken"
  }
]
```

## Specializations

All layer properties can have appearance or idiom-specific variations using the `-specializations` suffix:

- `opacity-specializations`
- `blend-mode-specializations` 
- `fill-specializations`
- `hidden-specializations`
- `position-specializations`

### Specialization Structure
```json
"property-specializations": [
  {
    "value": defaultValue
  },
  {
    "appearance": "dark|light|tinted",
    "value": specializedValue
  },
  {
    "idiom": "square|circle", 
    "value": specializedValue
  }
]
```
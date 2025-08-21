# Group Properties

## Basic Properties

### Visibility
```json
"hidden": false
```
Controls whether the entire group is visible.

### Blend Mode
```json
"blend-mode": "multiply"
```
How the group blends with layers below it. Observed values: `multiply`.

## Positioning

Groups can have their own positioning that affects all contained layers:
```json
"position": {
  "scale": 1.0,
  "translation-in-points": [x, y]
}
```

## Visual Effects

### Blur Material
```json
"blur-material": 0.8
```
Floating point value controlling blur intensity (0.0 to 1.0+).

### Translucency
```json
"translucency": {
  "enabled": true,
  "value": 0.5
}
```
- `enabled`: Boolean toggle for translucency effect
- `value`: Translucency amount (0.0 = opaque, 1.0 = fully transparent)

### Shadow
```json
"shadow": {
  "kind": "neutral|layer-color",
  "opacity": 0.5
}
```
- `kind`: Shadow type
  - `"neutral"`: Standard shadow
  - `"layer-color"`: Shadow matches layer colors
- `opacity`: Shadow opacity (0.0 to 1.0)

## Lighting

### Lighting Mode
```json
"lighting": "combined|individual"
```
- `"combined"`: Unified lighting across all layers in group
- `"individual"`: Each layer lit independently

### Specular Highlights
```json
"specular": true
```
Boolean controlling specular highlight rendering.

## Specializations

Group properties support the same specialization system as layers:

### Blur Material Specializations
```json
"blur-material-specializations": [
  {
    "value": 0.8
  },
  {
    "idiom": "square",
    "value": 1.0
  },
  {
    "appearance": "tinted", 
    "value": 1.0
  }
]
```

### Specular Specializations
```json
"specular-specializations": [
  {
    "appearance": "light",
    "value": false
  }
]
```

## Layers Array

Each group contains a `layers` array with layer definitions:
```json
"layers": [
  {
    "name": "LayerName",
    "image-name": "asset.png",
    // ... layer properties
  }
]
```

The order in the array determines rendering order (first = bottom, last = top).
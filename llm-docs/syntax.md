# .icon JSON Syntax

## Root Structure
```json
{
  "fill": { ... },
  "groups": [ ... ],
  "supported-platforms": { ... }
}
```

## Fill Types
```json
"fill": {
  "automatic-gradient": "extended-srgb:r,g,b,a"
}
```
```json
"fill": {
  "solid": "extended-srgb:r,g,b,a"
}
```

## Groups Array
```json
"groups": [
  {
    "layers": [ ... ],
    "position": { ... },
    "shadow": { ... },
    "translucency": { ... },
    "blur-material": 0.5,
    "lighting": "combined|individual",
    "specular": true|false,
    "blend-mode": "multiply",
    "hidden": false
  }
]
```

## Layers Array
```json
"layers": [
  {
    "name": "string",
    "image-name": "filename.png",
    "position": { ... },
    "fill": { ... },
    "hidden": false
  }
]
```

## Position Object
```json
"position": {
  "scale": 1.0,
  "translation-in-points": [x, y]
}
```

## Shadow Object
```json
"shadow": {
  "kind": "neutral|layer-color",
  "opacity": 0.5
}
```

## Translucency Object
```json
"translucency": {
  "enabled": true,
  "value": 0.5
}
```

## Specializations
Add `-specializations` to any property:
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

## Platform Support
```json
"supported-platforms": {
  "circles": ["watchOS"],
  "squares": "shared"
}
```

## Available Specialization Properties
- `opacity-specializations`
- `blend-mode-specializations`
- `fill-specializations`
- `hidden-specializations`
- `position-specializations`
- `blur-material-specializations`
- `specular-specializations`
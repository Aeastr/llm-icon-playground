# Specialization System

The .icon format uses a specialization system to provide different values for properties based on appearance modes and device idioms.

## How Specializations Work

Any property can have multiple values through specializations using the pattern `property-specializations`:

```json
"property-specializations": [
  {
    "value": defaultValue
  },
  {
    "appearance": "dark",
    "value": darkModeValue
  },
  {
    "idiom": "square",
    "value": squareDeviceValue
  }
]
```

## Appearance Modes

### Available Appearances
- `"light"`: Light mode
- `"dark"`: Dark mode  
- `"tinted"`: Tinted mode

### Examples

#### Opacity Variations
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

#### Visibility by Appearance
```json
"hidden-specializations": [
  {
    "appearance": "tinted",
    "value": true
  }
]
```

#### Fill Type Changes
```json
"fill-specializations": [
  {
    "appearance": "dark",
    "value": {
      "automatic-gradient": "extended-srgb:0.00000,0.53333,1.00000,1.00000"
    }
  }
]
```

#### Blend Mode Changes
```json
"blend-mode-specializations": [
  {
    "appearance": "dark",
    "value": "darken"
  }
]
```

## Device Idioms

### Available Idioms
- `"square"`: Square form factor (iOS, macOS)
- `"circle"`: Circular form factor (watchOS)

### Examples

#### Blur Intensity by Device
```json
"blur-material-specializations": [
  {
    "value": 0.8
  },
  {
    "idiom": "square",
    "value": 1.0
  }
]
```

#### Position Changes by Device
```json
"position-specializations": [
  {
    "appearance": "dark",
    "value": {
      "scale": 1,
      "translation-in-points": [168, 0]
    }
  }
]
```

## Supported Properties

### Layer Specializations
- `opacity-specializations`
- `blend-mode-specializations`
- `fill-specializations`
- `hidden-specializations` 
- `position-specializations`

### Group Specializations
- `blur-material-specializations`
- `specular-specializations`
- All layer specializations (when applied to groups)

## Resolution Order

When multiple specializations could apply:
1. Exact match (appearance + idiom)
2. Appearance match
3. Idiom match
4. Default value (no specialization keys)

## Default Values

Entries without `appearance` or `idiom` keys serve as the default:
```json
"opacity-specializations": [
  {
    "value": 1.0  // This is the default
  },
  {
    "appearance": "dark",
    "value": 0.5  // This overrides for dark mode
  }
]
```
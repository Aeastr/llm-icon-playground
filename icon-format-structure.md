# .icon Format Structure

## File Organization

### Directory Structure
```
IconName.icon/
├── icon.json          # Main configuration file
└── Assets/            # Image assets directory
    ├── image1.png     # Referenced by "image-name" in JSON
    ├── image2.png
    └── ...
```

### icon.json Schema

The main configuration file follows this hierarchical structure:

```json
{
  "fill": { ... },              // Root-level background fill
  "groups": [ ... ],            // Array of layer groups
  "supported-platforms": { ... } // Platform targeting
}
```

## Root Level Properties

### Fill
Defines the icon's background fill:
```json
"fill": {
  "automatic-gradient": "extended-srgb:0.00000,0.53333,1.00000,1.00000"
}
```

**Fill Types:**
- `automatic-gradient`: System-generated gradient with color value
- `solid`: Solid color fill
- `gradient`: Custom gradient definition

### Supported Platforms
Defines which platforms and form factors the icon supports:
```json
"supported-platforms": {
  "circles": ["watchOS"],     // Circular icons for watchOS
  "squares": "shared"         // Square icons for iOS/macOS
}
```

## Groups Structure

Groups are collections of layers that share positioning and effects:

```json
"groups": [
  {
    "layers": [ ... ],          // Array of layers in this group
    "position": { ... },        // Group positioning
    "shadow": { ... },          // Shadow effects
    "translucency": { ... },    // Translucency settings
    "blur-material": 0.5,       // Blur amount
    "lighting": "combined",     // Lighting mode
    "specular": true,           // Specular highlights
    "blend-mode": "multiply",   // Blend mode
    "hidden": false             // Visibility
  }
]
```

## Layers Structure

Layers contain the actual image content and positioning:

```json
"layers": [
  {
    "name": "LayerName",        // Layer identifier
    "image-name": "image.png",  // Asset filename
    "position": {               // Layer positioning
      "scale": 1,
      "translation-in-points": [x, y]
    },
    "fill": { ... },            // Layer fill override
    "hidden": false             // Layer visibility
  }
]
```

## Coordinate System

- **Translation**: Uses point-based coordinates `[x, y]`
- **Scale**: Floating point scale factor (1.0 = 100%)
- **Origin**: Appears to be center-based coordinate system
- **Positioning**: Can be applied at both group and layer levels
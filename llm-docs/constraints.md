# .icon Generation Constraints

## Hard Limits
- **Max groups**: 4
- **Max layers per group**: 8
- **Canvas size**: 1024x1024px

## Value Ranges
- **Scale**: 0.1 to 3.0
- **Translation**: -512 to 512 (keep within canvas bounds)
- **Blur material**: 0.0 to 1.0
- **Opacity**: 0.0 to 1.0
- **Translucency value**: 0.0 to 1.0
- **Shadow opacity**: 0.0 to 1.0

## Color Format
Extended sRGB: `"extended-srgb:r,g,b,a"`
- r,g,b,a values: 0.0 to 1.0

## Asset References
- Must use exact filenames from available assets
- Reference PNG files in Assets/ directory
- Use naming pattern: `[width]x[height]px[Shape][Rounding].png`

## Appearance Types
- `"light"` 
- `"dark"`
- `"tinted"`

## Idiom Types  
- `"square"` (iOS, macOS)
- `"circle"` (watchOS)

## Lighting Modes
- `"combined"`
- `"individual"`

## Shadow Kinds
- `"neutral"`
- `"layer-color"`

## Blend Modes
- `"multiply"`
- `"darken"`

## Platform Support
Always use:
```json
"supported-platforms": {
  "circles": ["watchOS"],
  "squares": "shared"  
}
```

## Asset Limitations
- **Cannot create custom shapes**: Must use only the assets listed in assets.md
- **Cannot use SF Symbols**: SF Symbol support not yet available
- **Asset creation**: Coming soon - future feature to generate custom assets on demand
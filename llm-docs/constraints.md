# .icon Generation Constraints

## Hard Limits
- **Max groups**: 4
- **Max layers per group**: 8
- **Canvas size**: 1024x1024px

## Value Ranges
- **Scale**: 0.01 to 5.0 (allows tiny details and large elements)
- **Translation**: -512 to 512 (keep within canvas bounds)
- **Blur material**: 0.0 to 1.0
- **Opacity**: 0.0 to 1.0
- **Translucency value**: 0.0 to 1.0
- **Shadow opacity**: 0.0 to 1.0

## Color Format
Extended sRGB: `"extended-srgb:r,g,b,a"`
- r,g,b,a values: 0.0 to 1.0

### Valid Fill Types for Icon Background
Icons must always have a fill. Valid fillType options:

1. **`"color"` or `"solid"`** - Solid color fill (requires `color` parameter)
   - `color`: Must be `extended-srgb:r,g,b,a` format (e.g., `extended-srgb:0.5,0.7,0.9,1.0`)
   
2. **`"automatic"`** - Apple automatic color (no color parameter needed)
   - Creates: `"fill": "automatic"`
   
3. **`"system-light"`** - Apple system light color (no color parameter needed)
   - Creates: `"fill": "system-light"`
   
4. **`"system-dark"`** - Apple system dark color (no color parameter needed)
   - Creates: `"fill": "system-dark"`
   
5. **`"automatic-gradient"`** - Apple automatic gradient (requires `color` parameter for base)
   - `color`: Must be `extended-srgb:r,g,b,a` format
   - Creates: `"fill": { "automatic-gradient": "color-value" }`

#### Invalid Fill Options
- Icons cannot have null/empty fills
- No `transparent`, `none`, `clear`, or `remove` options
- Icons must always have a real fill value
- No hex colors like `#FF0000` or named colors like `red` - use `extended-srgb:r,g,b,a` format only

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

## Important Rules
- **Background required**: Include either "fill" or "fill-specializations" at root level for background
- **Layer stacking order**: In layers array, first item = front (visible on top), last item = back
- **Cannot create custom shapes**: Must use only the assets listed in assets.md  
- **Cannot use SF Symbols**: SF Symbol support not yet available
- **Asset creation**: Coming soon - future feature to generate custom assets on demand
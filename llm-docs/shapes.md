# Available Shapes

Asset library for .icon generation. All assets are SVG format with the naming pattern: `[width]x[height]px[Shape][Rounding].svg`

## How Sizing Works
- All shapes have their native size as SVG bounds (e.g., 1024x1024px, 1024x512px)
- Use the `scale` property in positioning to resize: `"scale": 0.5` = 50% of native size
- Icon canvas is 1024x1024px total

### Circles
- `1024x1024pxCircle.svg`

### Rectangles  
- `1024x1024pxRectangle.svg`
- `1024x512pxRectangle.svg` (wide)
- `512x1024pxRectangle.svg` (tall)

### Rounded Rectangles
- `1024x1024pxRoundedRectangle60px.svg`
- `1024x1024pxRoundedRectangle100px.svg`
- `1024x512pxRoundedRectangle40px.svg` (wide)

### Ellipses
- `1024x512pxEllipse.svg` (wide oval)
- `512x1024pxEllipse.svg` (tall oval)

### Triangles
- `1024x1024pxTriangle.svg`

### Stars
- `1024x1024pxStar5pt.svg` (5-pointed star)
- `1024x1024pxStar6pt.svg` (6-pointed star)

### Lines/Strokes
- `1024x64pxRectangle.svg` (horizontal line)
- `64x1024pxRectangle.svg` (vertical line)
- `1024x128pxRoundedRectangle64px.svg` (thick rounded line)

### Specialty Shapes
- `1024x1024pxHexagon.svg`
- `1024x1024pxDiamond.svg`
- `1024x1024pxHeart.svg`
- `1024x512pxPill.svg` (very rounded rectangle)

### Text/Symbols
- `512x512pxPlus.svg` (+ symbol)
- `512x512pxMinus.svg` (- symbol)
- `512x512pxX.svg` (× symbol)
- `512x512pxCheck.svg` (✓ symbol)

## Notes
- All assets are SVG with scalable vector graphics
- Rounding values indicate corner radius in pixels at native size
- Use scale property to resize: scale 0.25 = 25% of native size
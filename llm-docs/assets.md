# Available Assets

Reference these exact filenames in `"image-name"` properties. All assets are SVG format.

## Sizing
- Native size is in the filename (e.g., 1024x1024px)
- Use `scale` property to resize: `"scale": 0.5` = 50% of native size
- Icon canvas: 1024x1024px

## Circles
- `1024x1024pxCircle.svg`

## Rectangles
- `1024x1024pxRectangle.svg`
- `1024x512pxRectangle.svg`
- `512x1024pxRectangle.svg`

## Rounded Rectangles
- `1024x1024pxRoundedRectangle60px.svg`
- `1024x1024pxRoundedRectangle100px.svg`
- `1024x512pxRoundedRectangle40px.svg`

## Lines
- `1024x64pxRectangle.svg`
- `64x1024pxRectangle.svg`
- `1024x128pxRoundedRectangle64px.svg`

## Triangles
- `1024x1024pxTriangle.svg`

## Stars
- `1024x1024pxStar5pt.svg`
- `1024x1024pxStar6pt.svg`

## Symbols
- `512x512pxPlus.svg`
- `512x512pxMinus.svg`
- `512x512pxX.svg`
- `512x512pxCheck.svg`

## Usage
Use exact filename in JSON:
```json
"image-name": "1024x1024pxCircle.svg"
```

Scale to desired size:
```json
"position": {
  "scale": 0.5,
  "translation-in-points": [0, 0]
}
```
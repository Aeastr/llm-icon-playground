# .icon Examples

## Minimal Icon
```json
{
  "fill": {
    "solid": "extended-srgb:0.0,0.5,1.0,1.0"
  },
  "groups": [
    {
      "layers": [
        {
          "name": "Main",
          "image-name": "1024x1024pxCircle.svg",
          "position": {
            "scale": 0.5,
            "translation-in-points": [0, 0]
          }
        }
      ]
    }
  ],
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```

## With Effects
```json
{
  "fill": {
    "solid": "extended-srgb:0.2,0.2,0.2,1.0"
  },
  "groups": [
    {
      "blur-material": 0.3,
      "translucency": {
        "enabled": true,
        "value": 0.7
      },
      "shadow": {
        "kind": "neutral",
        "opacity": 0.5
      },
      "layers": [
        {
          "name": "Background",
          "image-name": "1024x1024pxRoundedRectangle100px.svg",
          "position": {
            "scale": 0.75,
            "translation-in-points": [0, 0]
          }
        }
      ]
    }
  ],
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```

## With Specializations
```json
{
  "fill": {
    "solid": "extended-srgb:0.2,0.2,0.2,1.0"
  },
  "groups": [
    {
      "layers": [
        {
          "name": "Icon",
          "image-name": "1024x1024pxStar5pt.svg",
          "opacity-specializations": [
            {
              "value": 1.0
            },
            {
              "appearance": "dark",
              "value": 0.6
            }
          ],
          "position-specializations": [
            {
              "value": {
                "scale": 1.0,
                "translation-in-points": [0, 0]
              }
            },
            {
              "idiom": "circle",
              "value": {
                "scale": 0.8,
                "translation-in-points": [10, 10]
              }
            }
          ]
        }
      ]
    }
  ],
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  }
}
```
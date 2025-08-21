# Platform Support and Targeting

## Supported Platforms Declaration

The root level `supported-platforms` object defines which platforms and form factors the icon supports:

```json
"supported-platforms": {
  "circles": ["watchOS"],
  "squares": "shared"
}
```

## Form Factors

### Circles
Used for circular icon displays:
```json
"circles": ["watchOS"]
```
- Array of platform names that use circular icons
- Primarily watchOS devices

### Squares  
Used for square/rectangular icon displays:
```json
"squares": "shared"
```
- Can be an array of specific platforms or `"shared"` for all square platforms
- Includes iOS, macOS, and other square form factor devices

## Platform-Specific Behavior

### Idiom Specializations
The specialization system uses `idiom` to target different form factors:

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

### Available Idioms
- `"square"`: Square form factor devices
- `"circle"`: Circular form factor devices (watchOS)

## Platform Targeting Strategy

### Single Icon, Multiple Platforms
One `.icon` file can target multiple platforms by:
1. Declaring support in `supported-platforms`
2. Using idiom specializations for form factor differences
3. Using appearance specializations for platform-specific modes

### Example Multi-Platform Icon
```json
{
  "supported-platforms": {
    "circles": ["watchOS"],
    "squares": "shared"
  },
  "groups": [
    {
      "blur-material-specializations": [
        {
          "value": 0.5
        },
        {
          "idiom": "circle",
          "value": 0.8
        }
      ],
      "layers": [
        {
          "position-specializations": [
            {
              "value": {
                "scale": 1,
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
  ]
}
```

This allows different blur intensities and positioning for square vs circular displays while maintaining a single icon definition.
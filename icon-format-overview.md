# .icon Format Documentation

## Overview

The `.icon` format is a JSON and asset-based icon system introduced in OS 26. It uses a layered composition system with visual effects and appearance variations.

## What it contains

- JSON configuration file defining layers, groups, and effects
- PNG assets referenced by the JSON
- Appearance-specific variations (light/dark/tinted modes)
- Device form factor targeting (square/circle)
- Visual effects: blur, translucency, shadows, specular lighting, blend modes

## How it works

`.icon` files describe how to render icons using:
- Groups containing multiple layers
- Positioning and scaling for each element  
- Effect parameters (blur amounts, shadow types, etc.)
- Specializations that change properties based on appearance or device type

## Asset structure
PNG images are stored separately and referenced by filename in the JSON configuration.

## Viewing and Rendering

**.icon files require Xcode's Icon Composer App for viewing.** Icon Composer shows a preview of how the icon will appear on the respective operating systems.

The actual visual effects are rendered by the OS:
- **macOS, iOS, watchOS** apply the effects defined in the JSON
- **Liquid glass** and **specular highlights** are dynamic effects that respond to device tilt and lighting
- **Blur, translucency, shadows** are rendered according to the specifications

## Format Structure

```
MyIcon.icon/
├── icon.json          # Main configuration file
└── Assets/            # Image assets directory
    ├── image1.png
    ├── image2.png
    └── ...
```

The `icon.json` file contains the complete icon definition with hierarchical structure:
- Root configuration (fill, platform support)
- Groups (collections of layers with shared effects)
- Layers (individual image elements with positioning)
- Specializations (appearance/device-specific variations)
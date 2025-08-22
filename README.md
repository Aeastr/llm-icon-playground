please ignore the disgusting UI, for now

# LLM Icon Playground

An experimental macOS app that uses LLMs to generate Apple's new .icon format files from text descriptions.

## What It Does

This is a small experiment to see if we can get LLMs to understand and generate Apple's complex .icon format (introduced in OS 26). The app:

- Takes a text description like "a blue music note with a shadow"
- Uses an LLM API to generate a valid .icon JSON structure
- Creates the complete .icon file with assets for Icon Composer

## Features

- **Structured Output**: Uses JSON Schema to ensure reliable .icon generation
- **Fallback System**: Falls back to unstructured parsing if structured output fails
- **Layer Understanding**: LLM learns proper layer stacking (front-to-back ordering)
- **Asset Management**: Includes SVG shapes that get copied into .icon bundles
- **Secure API Storage**: API keys stored in macOS Keychain
- **Model Selection**: Choose between different Gemini models

## Current Status

🧪 **Experimental** - This is just a proof of concept to see what's possible with LLM-generated icon files.

## Requirements

- macOS (for Icon Composer and .icon format support)
- Gemini API key

## .icon Format Documentation

- [**Overview**](docs/icon-format-overview.md) - What the .icon format is and how it works
- [**Structure**](docs/icon-format-structure.md) - File organization and JSON schema  
- [**Layer Properties**](docs/layer-properties.md) - Layer-specific properties and effects
- [**Group Properties**](docs/group-properties.md) - Group-level effects and positioning
- [**Specializations**](docs/specializations.md) - Appearance and device variations
- [**Platform Support**](docs/platform-support.md) - Platform targeting and form factors

## Example

See `RandomTest.icon/` for a working Apple example with multiple layers, groups, and specializations.

## Limitations

- Cannot create custom shapes (uses predefined SVG assets only)
- No SF Symbols support yet
- Limited to available geometric shapes
- Experimental - results may vary
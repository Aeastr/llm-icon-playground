# LLM Tools Reference

This document tracks all the tools/functions we provide to the LLM for icon analysis and editing.

## Current Tools (Read-Only Analysis)

### Icon Level
- **`readIconConfig`** - Get overview of the icon (background, group count, specializations)
  - Parameters: None
  - Returns: Background fill, total groups, total layers, specializations info

### Group Level  
- **`readIconGroups`** - List all groups with indices and layer counts
  - Parameters: None
  - Returns: Array of groups with names and layer counts

- **`getIconGroupDetails`** - Get detailed info about a specific group
  - Parameters: `groupIndex` (string)
  - Returns: Group name, position, scale, rotation, layer count, etc.

### Layer Level
- **`readLayers`** - List all layers in a specific group
  - Parameters: `groupIndex` (string) 
  - Returns: Array of layer names and asset types

- **`getLayerDetails`** - Get detailed info about a specific layer
  - Parameters: `groupIndex` (string), `layerIndex` (string)
  - Returns: Layer name, asset, position, fill colors, effects, etc.

## Planned Tools (Editing)

### Icon Level
- **`updateIconBackground`** - Change background fill
  - Parameters: `fillType`, `color`/`gradient`
  - Returns: Success/failure

- **`addIconFillSpecialization`** - Add background appearance variant (dark mode, etc.)
  - Parameters: `appearance` (light/dark), `fillType`, `color`/`gradient`
  - Returns: Success/failure

- **`removeIconFillSpecialization`** - Remove background appearance variant
  - Parameters: `appearance` (light/dark)
  - Returns: Success/failure

### Group Level
- **`addGroup`** - Create new group
  - Parameters: `name`, `position`?, `layers`?
  - Returns: New group index

- **`removeGroup`** - Delete group and all its layers
  - Parameters: `groupIndex`
  - Returns: Success/failure

- **`editGroupPosition`** - Move/scale/rotate group
  - Parameters: `groupIndex`, `x`?, `y`?, `scale`?, `rotation`?
  - Returns: Success/failure

- **`renameGroup`** - Change group name
  - Parameters: `groupIndex`, `newName`
  - Returns: Success/failure

#### Group Specializations
- **`addGroupBlurMaterialSpecialization`** - Add blur effect variant
  - Parameters: `groupIndex`, `appearance`?, `idiom`?, `value`
  - Returns: Success/failure

- **`addGroupSpecularSpecialization`** - Add specular lighting variant
  - Parameters: `groupIndex`, `appearance`?, `idiom`?, `value`
  - Returns: Success/failure

- **`removeGroupSpecialization`** - Remove group specialization
  - Parameters: `groupIndex`, `specializationType`, `appearance`?, `idiom`?
  - Returns: Success/failure

### Layer Level
- **`addLayer`** - Add new layer to group
  - Parameters: `groupIndex`, `assetName`, `fill`?, `position`?
  - Returns: New layer index

- **`removeLayer`** - Delete layer
  - Parameters: `groupIndex`, `layerIndex`
  - Returns: Success/failure

- **`editLayerPosition`** - Move/scale/rotate layer
  - Parameters: `groupIndex`, `layerIndex`, `x`?, `y`?, `scale`?, `rotation`?
  - Returns: Success/failure

- **`editLayerFill`** - Change layer colors
  - Parameters: `groupIndex`, `layerIndex`, `fillType`, `color`/`gradient`
  - Returns: Success/failure

- **`editLayerAsset`** - Change layer shape/asset
  - Parameters: `groupIndex`, `layerIndex`, `newAssetName`
  - Returns: Success/failure

- **`reorderLayers`** - Change layer z-order
  - Parameters: `groupIndex`, `fromIndex`, `toIndex`
  - Returns: Success/failure

#### Layer Specializations
- **`addLayerOpacitySpecialization`** - Add opacity variant
  - Parameters: `groupIndex`, `layerIndex`, `appearance`?, `idiom`?, `value`
  - Returns: Success/failure

- **`addLayerBlendModeSpecialization`** - Add blend mode variant
  - Parameters: `groupIndex`, `layerIndex`, `appearance`?, `idiom`?, `blendMode`
  - Returns: Success/failure

- **`addLayerFillSpecialization`** - Add fill color variant
  - Parameters: `groupIndex`, `layerIndex`, `appearance`?, `idiom`?, `fillType`, `color`/`gradient`
  - Returns: Success/failure

- **`addLayerHiddenSpecialization`** - Add visibility variant
  - Parameters: `groupIndex`, `layerIndex`, `appearance`?, `idiom`?, `hidden`
  - Returns: Success/failure

- **`addLayerPositionSpecialization`** - Add position variant
  - Parameters: `groupIndex`, `layerIndex`, `appearance`?, `idiom`?, `x`?, `y`?, `scale`?, `rotation`?
  - Returns: Success/failure

- **`removeLayerSpecialization`** - Remove layer specialization
  - Parameters: `groupIndex`, `layerIndex`, `specializationType`, `appearance`?, `idiom`?
  - Returns: Success/failure

### Advanced Editing
- **`applyIconPatch`** - Apply complex JSON patch for multi-step edits
  - Parameters: `jsonPatch` (JSON Patch format string)
  - Returns: Success/failure with validation errors

## Implementation Notes

### Current Status
- ✅ All read-only tools implemented
- ⏳ Editing tools in planning phase

### Design Decisions
- **Surgical edits** preferred over full JSON replacement
- **String parameters** for indices (Gemini API limitation)
- **Optional parameters** use `?` notation for clarity
- **Validation** built into each tool to prevent malformed icons
- **Backup system** automatically saves original before edits

### Error Handling
- All tools return `ToolResult.success(message)` or `ToolResult.error(message)`
- Validation errors are descriptive and actionable
- File I/O errors are caught and reported cleanly

### Future Considerations
- **Undo/Redo system** - Track edit history
- **Live preview** - Show changes in real-time
- **Asset management** - Validate asset references
- **Batch operations** - Multiple edits in single call
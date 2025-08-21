//
//  IconGenerator.swift
//  llm icon playground
//
//  Functions to create .icon files
//

import Foundation

enum IconGeneratorError: Error {
    case directoryCreationFailed
    case jsonWriteFailed
    case assetCopyFailed(String)
    case invalidOutputPath
}

class IconGenerator {
    
    /// Creates a .icon directory structure and writes the icon.json file
    /// - Parameters:
    ///   - iconData: The icon structure to encode
    ///   - outputDirectory: Directory where the .icon folder should be created
    ///   - iconName: Name for the .icon folder (without .icon extension)
    /// - Throws: IconGeneratorError
    static func createIconFile(
        iconData: IconFile,
        outputDirectory: URL,
        iconName: String
    ) throws {
        
        // Create .icon directory
        let iconDirectory = outputDirectory.appendingPathComponent("\(iconName).icon")
        let assetsDirectory = iconDirectory.appendingPathComponent("Assets")
        
        try FileManager.default.createDirectory(
            at: iconDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        try FileManager.default.createDirectory(
            at: assetsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Write icon.json
        try writeIconJSON(iconData: iconData, to: iconDirectory)
        
        // Extract and copy required assets
        let requiredAssets = extractRequiredAssets(from: iconData)
        try copyAssets(assetNames: requiredAssets, to: assetsDirectory)
    }
    
    /// Writes the icon.json file
    private static func writeIconJSON(iconData: IconFile, to directory: URL) throws {
        let jsonURL = directory.appendingPathComponent("icon.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(iconData)
            try jsonData.write(to: jsonURL)
        } catch {
            throw IconGeneratorError.jsonWriteFailed
        }
    }
    
    /// Extracts all asset filenames referenced in the icon data
    private static func extractRequiredAssets(from iconData: IconFile) -> Set<String> {
        var assets = Set<String>()
        
        for group in iconData.groups {
            for layer in group.layers {
                assets.insert(layer.imageName)
            }
        }
        
        return assets
    }
    
    /// Copies required assets from app bundle to the Assets directory
    private static func copyAssets(assetNames: Set<String>, to assetsDirectory: URL) throws {
        for assetName in assetNames {
            try copyAsset(named: assetName, to: assetsDirectory)
        }
    }
    
    /// Copies a single asset from the app bundle
    private static func copyAsset(named assetName: String, to assetsDirectory: URL) throws {
        // For now, we'll look for assets in the main bundle
        // This will need to be updated once you add assets to the catalog
        
        guard let assetURL = Bundle.main.url(forResource: assetName, withExtension: nil) else {
            throw IconGeneratorError.assetCopyFailed("Asset not found: \(assetName)")
        }
        
        let destinationURL = assetsDirectory.appendingPathComponent(assetName)
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: assetURL, to: destinationURL)
        } catch {
            throw IconGeneratorError.assetCopyFailed("Failed to copy \(assetName): \(error.localizedDescription)")
        }
    }
}

// MARK: - Convenience Initializers
extension IconFile {
    
    /// Creates a simple icon with default platform support
    static func simple(
        fill: Fill? = nil,
        groups: [Group]
    ) -> IconFile {
        return IconFile(
            fill: fill,
            groups: groups,
            supportedPlatforms: SupportedPlatforms(
                circles: ["watchOS"],
                squares: "shared"
            )
        )
    }
}

extension Group {
    
    /// Creates a simple group with just layers
    static func simple(layers: [Layer]) -> Group {
        return Group(
            layers: layers,
            position: nil,
            shadow: nil,
            translucency: nil,
            blurMaterial: nil,
            lighting: nil,
            specular: nil,
            blendMode: nil,
            hidden: nil,
            blurMaterialSpecializations: nil,
            specularSpecializations: nil
        )
    }
}

extension Layer {
    
    /// Creates a simple layer with just image and optional position
    static func simple(
        name: String,
        imageName: String,
        position: Position? = nil
    ) -> Layer {
        return Layer(
            name: name,
            imageName: imageName,
            position: position,
            fill: nil,
            hidden: nil,
            opacitySpecializations: nil,
            blendModeSpecializations: nil,
            fillSpecializations: nil,
            hiddenSpecializations: nil,
            positionSpecializations: nil
        )
    }
}
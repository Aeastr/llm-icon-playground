//
//  IconGenerator.swift
//  llm icon playground
//
//  Functions to create .icon files
//

import Foundation
import AppKit

struct GenerationInfo: Codable {
    let model: String
    let prompt: String
    let temperature: Double?
    let timestamp: Date
    
    init(model: String, prompt: String, temperature: Double? = nil) {
        self.model = model
        self.prompt = prompt
        self.temperature = temperature
        self.timestamp = Date()
    }
}

enum IconGeneratorError: Error, LocalizedError {
    case directoryCreationFailed(String)
    case jsonWriteFailed(String)
    case assetCopyFailed(String)
    case invalidOutputPath
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let message):
            return "Failed to create directory: \(message)"
        case .jsonWriteFailed(let message):
            return "Failed to write JSON: \(message)"
        case .assetCopyFailed(let message):
            return "Failed to copy asset: \(message)"
        case .invalidOutputPath:
            return "Invalid output path provided"
        }
    }
}

class IconGenerator {
    
    /// Creates a .icon directory structure and writes the icon.json file
    /// - Parameters:
    ///   - iconData: The icon structure to encode
    ///   - outputDirectory: Directory where the .icon folder should be created
    ///   - iconName: Name for the .icon folder (without .icon extension)
    ///   - generationInfo: Optional metadata about how the icon was generated
    /// - Throws: IconGeneratorError
    static func createIconFile(
        iconData: IconFile,
        outputDirectory: URL,
        iconName: String,
        generationInfo: GenerationInfo? = nil,
        useModelFolder: Bool = false
    ) throws {
        
        // Determine the final output directory
        let finalOutputDirectory: URL
        if useModelFolder, let generationInfo = generationInfo {
            let modelFolderName = generationInfo.model.replacingOccurrences(of: " ", with: "-")
            finalOutputDirectory = outputDirectory.appendingPathComponent(modelFolderName)
            
            // Create model folder if it doesn't exist
            try FileManager.default.createDirectory(
                at: finalOutputDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } else {
            finalOutputDirectory = outputDirectory
        }
        
        // Create .icon directory
        let iconDirectory = finalOutputDirectory.appendingPathComponent("\(iconName).icon")
        let assetsDirectory = iconDirectory.appendingPathComponent("Assets")
        
        do {
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
        } catch {
            throw IconGeneratorError.directoryCreationFailed(error.localizedDescription)
        }
        
        // Write icon.json
        try writeIconJSON(iconData: iconData, to: iconDirectory)
        
        // Write generationInfo.json if provided
        if let generationInfo = generationInfo {
            try writeGenerationInfoJSON(generationInfo: generationInfo, to: iconDirectory)
        }
        
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
            throw IconGeneratorError.jsonWriteFailed(error.localizedDescription)
        }
    }
    
    /// Writes the generationInfo.json file
    private static func writeGenerationInfoJSON(generationInfo: GenerationInfo, to directory: URL) throws {
        let jsonURL = directory.appendingPathComponent("generationInfo.json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(generationInfo)
            try jsonData.write(to: jsonURL)
        } catch {
            throw IconGeneratorError.jsonWriteFailed(error.localizedDescription)
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
        print("Copying \(assetNames.count) assets: \(assetNames)")
        for assetName in assetNames {
            print("Copying asset: \(assetName)")
            try copyAsset(named: assetName, to: assetsDirectory)
            print("Successfully copied: \(assetName)")
        }
    }
    
    /// Copies a single asset from the app bundle
    private static func copyAsset(named assetName: String, to assetsDirectory: URL) throws {
        // Look for the asset directly in the main bundle (no subdirectory)
        guard let assetURL = Bundle.main.url(forResource: assetName, withExtension: nil) else {
            throw IconGeneratorError.assetCopyFailed("Asset not found in bundle: \(assetName)")
        }
        
        print("Found asset at: bundle/\(assetName)")
        
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
    
    /// Recursively lists directory contents for debugging
    private static func listDirectoryContents(at url: URL, prefix: String) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
            for itemURL in contents {
                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
                if resourceValues.isDirectory == true {
                    print("📁 \(prefix)/\(itemURL.lastPathComponent)/")
                    listDirectoryContents(at: itemURL, prefix: "\(prefix)/\(itemURL.lastPathComponent)")
                } else {
                    print("📄 \(prefix)/\(itemURL.lastPathComponent)")
                }
            }
        } catch {
            print("Could not list contents of \(prefix): \(error)")
        }
    }
}

// MARK: - Convenience Initializers
extension IconFile {
    
    /// Creates a simple icon with default platform support
    static func simple(
        fill: Fill? = nil,
        groups: [IconGroup]
    ) -> IconFile {
        return IconFile(
            fill: fill,
            fillSpecializations: nil,
            groups: groups,
            supportedPlatforms: SupportedPlatforms(
                circles: ["watchOS"],
                squares: "shared"
            )
        )
    }
}

extension IconGroup {
    
    /// Creates a simple group with just layers
    static func simple(layers: [Layer]) -> IconGroup {
        return IconGroup(
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

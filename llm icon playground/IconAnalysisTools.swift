//
//  IconAnalysisTools.swift
//  llm icon playground
//
//  Tools for analyzing and reading .icon file structures
//

import Foundation

struct IconAnalysisTools {
    static func readJsonConfig(iconFileURL: URL) throws -> IconFile {
        let iconJsonURL = iconFileURL.appendingPathComponent("icon.json")
        
        guard FileManager.default.fileExists(atPath: iconJsonURL.path) else {
            throw IconAnalysisError.iconJsonNotFound
        }
        
        let data = try Data(contentsOf: iconJsonURL)
        let decoder = JSONDecoder()
        let iconFile = try decoder.decode(IconFile.self, from: data)
        
        return iconFile
    }
    
    static func readIconGroups(iconFileURL: URL) throws -> [String] {
        let iconFile = try readJsonConfig(iconFileURL: iconFileURL)
        
        return iconFile.groups.enumerated().map { index, group in
            return "\(index): IconGroup \(index + 1) (\(group.layers.count) layers)"
        }
    }
    
    static func readLayers(iconFileURL: URL, groupIndex: Int) throws -> [String] {
        let iconFile = try readJsonConfig(iconFileURL: iconFileURL)
        
        guard groupIndex >= 0 && groupIndex < iconFile.groups.count else {
            throw IconAnalysisError.groupNotFound(groupIndex)
        }
        
        let group = iconFile.groups[groupIndex]
        
        return group.layers.enumerated().map { index, layer in
            return "\(index): \(layer.name) (\(layer.imageName))"
        }
    }
    
    static func readIconConfig(iconFileURL: URL) throws -> IconConfigSummary {
        let iconFile = try readJsonConfig(iconFileURL: iconFileURL)
        
        return IconConfigSummary(
            backgroundFill: iconFile.fill?.description ?? "No background fill",
            groupCount: iconFile.groups.count,
            totalLayers: iconFile.groups.reduce(0) { sum, group in
                sum + group.layers.count
            },
            hasSpecializations: iconFile.fillSpecializations != nil && !iconFile.fillSpecializations!.isEmpty
        )
    }
    
    static func getLayerDetails(iconFileURL: URL, groupIndex: Int, layerIndex: Int) throws -> LayerSummary {
        let iconFile = try readJsonConfig(iconFileURL: iconFileURL)
        
        guard groupIndex >= 0 && groupIndex < iconFile.groups.count else {
            throw IconAnalysisError.groupNotFound(groupIndex)
        }
        
        let group = iconFile.groups[groupIndex]
        
        guard layerIndex >= 0 && layerIndex < group.layers.count else {
            throw IconAnalysisError.layerNotFound(layerIndex)
        }
        
        let layer = group.layers[layerIndex]
        
        return LayerSummary(
            name: layer.name,
            imageName: layer.imageName,
            position: layer.position?.description ?? "Default position",
            fill: layer.fill?.description ?? "No fill",
            hidden: layer.hidden ?? false
        )
    }
    
    static func getIconGroupDetails(iconFileURL: URL, groupIndex: Int) throws -> IconGroupSummary {
        let iconFile = try readJsonConfig(iconFileURL: iconFileURL)
        
        guard groupIndex >= 0 && groupIndex < iconFile.groups.count else {
            throw IconAnalysisError.groupNotFound(groupIndex)
        }
        
        let group = iconFile.groups[groupIndex]
        
        return IconGroupSummary(
            name: "IconGroup \(groupIndex + 1)",
            layerCount: group.layers.count,
            position: group.position?.description ?? "Default position",
            shadow: group.shadow?.description ?? "No shadow",
            lighting: group.lighting ?? "No lighting",
            blendMode: group.blendMode ?? "Normal",
            hidden: group.hidden ?? false
        )
    }
}

// MARK: - Helper Types

struct IconConfigSummary {
    let backgroundFill: String
    let groupCount: Int
    let totalLayers: Int
    let hasSpecializations: Bool
    
    var description: String {
        return """
        Background: \(backgroundFill)
        IconGroups: \(groupCount)
        Total Layers: \(totalLayers)
        Has Specializations: \(hasSpecializations)
        """
    }
}

struct LayerSummary {
    let name: String
    let imageName: String
    let position: String
    let fill: String
    let hidden: Bool
    
    var description: String {
        return """
        Name: \(name)
        Image: \(imageName)
        Position: \(position)
        Fill: \(fill)
        Hidden: \(hidden)
        """
    }
}

struct IconGroupSummary {
    let name: String
    let layerCount: Int
    let position: String
    let shadow: String
    let lighting: String
    let blendMode: String
    let hidden: Bool
    
    var description: String {
        return """
        Name: \(name)
        Layers: \(layerCount)
        Position: \(position)
        Shadow: \(shadow)
        Lighting: \(lighting)
        Blend Mode: \(blendMode)
        Hidden: \(hidden)
        """
    }
}

enum IconAnalysisError: LocalizedError {
    case iconJsonNotFound
    case groupNotFound(Int)
    case layerNotFound(Int)
    case invalidIconStructure
    
    var errorDescription: String? {
        switch self {
        case .iconJsonNotFound:
            return "icon.json file not found in the selected .icon bundle"
        case .groupNotFound(let index):
            return "IconGroup at index \(index) not found"
        case .layerNotFound(let index):
            return "Layer at index \(index) not found"
        case .invalidIconStructure:
            return "Invalid icon file structure"
        }
    }
}

// MARK: - Extensions for better descriptions

extension Fill {
    var description: String {
        if let solid = solid {
            return "Solid: \(solid)"
        } else if let gradient = automaticGradient {
            return "Gradient: \(gradient)"
        }
        return "No fill"
    }
}

extension Position {
    var description: String {
        return "Scale: \(scale), Translation: [\(translationInPoints.first ?? 0), \(translationInPoints.last ?? 0)]"
    }
}

extension Shadow {
    var description: String {
        return "\(kind) shadow (opacity: \(opacity))"
    }
}

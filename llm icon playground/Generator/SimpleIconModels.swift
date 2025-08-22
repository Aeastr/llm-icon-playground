//
//  SimpleIconModels.swift
//  llm icon playground
//
//  Simplified data models for .icon format (no schema generation)
//

import Foundation

// MARK: - Root Icon Structure
struct IconFile: Codable {
    let fill: Fill?
    let fillSpecializations: [FillSpecialization]?
    let groups: [IconGroup]
    let supportedPlatforms: SupportedPlatforms
    
    enum CodingKeys: String, CodingKey {
        case fill, groups
        case fillSpecializations = "fill-specializations"
        case supportedPlatforms = "supported-platforms"
    }
}

// MARK: - Fill
struct Fill: Codable {
    let automaticGradient: String?
    let solid: String?
    
    enum CodingKeys: String, CodingKey {
        case automaticGradient = "automatic-gradient"
        case solid
    }
}

// MARK: - IconGroup  
struct IconGroup: Codable {
    let layers: [Layer]
    let position: Position?
    let shadow: Shadow?
    let translucency: Translucency?
    let blurMaterial: Double?
    let lighting: String?
    let specular: Bool?
    let blendMode: String?
    let hidden: Bool?
    
    // Specializations
    let blurMaterialSpecializations: [BlurMaterialSpecialization]?
    let specularSpecializations: [SpecularSpecialization]?
    
    enum CodingKeys: String, CodingKey {
        case layers, position, shadow, translucency, lighting, specular, hidden
        case blurMaterial = "blur-material"
        case blendMode = "blend-mode"
        case blurMaterialSpecializations = "blur-material-specializations"
        case specularSpecializations = "specular-specializations"
    }
}

// MARK: - Layer
struct Layer: Codable {
    let name: String
    let imageName: String
    let position: Position?
    let fill: Fill?
    let hidden: Bool?
    
    // Specializations
    let opacitySpecializations: [OpacitySpecialization]?
    let blendModeSpecializations: [BlendModeSpecialization]?
    let fillSpecializations: [FillSpecialization]?
    let hiddenSpecializations: [HiddenSpecialization]?
    let positionSpecializations: [PositionSpecialization]?
    
    enum CodingKeys: String, CodingKey {
        case name, position, fill, hidden
        case imageName = "image-name"
        case opacitySpecializations = "opacity-specializations"
        case blendModeSpecializations = "blend-mode-specializations"
        case fillSpecializations = "fill-specializations"
        case hiddenSpecializations = "hidden-specializations"
        case positionSpecializations = "position-specializations"
    }
}

// MARK: - Position
struct Position: Codable {
    let scale: Double
    let translationInPoints: [Double]
    
    enum CodingKeys: String, CodingKey {
        case scale
        case translationInPoints = "translation-in-points"
    }
}

// MARK: - Shadow
struct Shadow: Codable {
    let kind: String
    let opacity: Double
}

// MARK: - Translucency
struct Translucency: Codable {
    let enabled: Bool
    let value: Double
}

// MARK: - Supported Platforms
struct SupportedPlatforms: Codable {
    let circles: [String]?
    let squares: String?
}

// MARK: - Specializations
struct OpacitySpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Double
}

struct BlendModeSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: String
}

struct FillSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Fill
}

struct HiddenSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Bool
}

struct PositionSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Position
}

struct BlurMaterialSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Double
}

struct SpecularSpecialization: Codable {
    let appearance: String?
    let idiom: String?
    let value: Bool
}

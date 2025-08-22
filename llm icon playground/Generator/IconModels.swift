//
//  IconModels.swift
//  llm icon playground
//
//  Data models for .icon format
//

import Foundation

// MARK: - Schema Generation Protocol
protocol JSONSchemaConvertible {
    static func jsonSchema() -> SchemaProperty
}

extension SchemaProperty {
    static func object(properties: [String: AnyCodable], required: [String]? = nil) -> SchemaProperty {
        return SchemaProperty(
            type: "object",
            properties: properties,
            items: nil,
            required: required,
            enumValues: nil
        )
    }
    
    static func array(items: SchemaProperty) -> SchemaProperty {
        return SchemaProperty(
            type: "array",
            properties: nil,
            items: AnyCodable(items),
            required: nil,
            enumValues: nil
        )
    }
    
    static func string(enumValues: [String]? = nil) -> SchemaProperty {
        return SchemaProperty(
            type: "string",
            properties: nil,
            items: nil,
            required: nil,
            enumValues: enumValues
        )
    }
    
    static func number() -> SchemaProperty {
        return SchemaProperty(
            type: "number",
            properties: nil,
            items: nil,
            required: nil,
            enumValues: nil
        )
    }
    
    static func boolean() -> SchemaProperty {
        return SchemaProperty(
            type: "boolean",
            properties: nil,
            items: nil,
            required: nil,
            enumValues: nil
        )
    }
}

// MARK: - Root Icon Structure
struct IconFile: Codable, JSONSchemaConvertible {
    let fill: Fill?
    let fillSpecializations: [FillSpecialization]?
    let groups: [Group]
    let supportedPlatforms: SupportedPlatforms
    
    enum CodingKeys: String, CodingKey {
        case fill, groups
        case fillSpecializations = "fill-specializations"
        case supportedPlatforms = "supported-platforms"
    }
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "fill": AnyCodable(Fill.jsonSchema()),
            "fill-specializations": AnyCodable(SchemaProperty.array(items: FillSpecialization.jsonSchema())),
            "groups": AnyCodable(SchemaProperty.array(items: Group.jsonSchema())),
            "supported-platforms": AnyCodable(SupportedPlatforms.jsonSchema())
        ], required: ["groups", "supported-platforms"])
    }
    
    static func responseSchema() -> ResponseSchema {
        return ResponseSchema(
            type: "object",
            properties: [
                "fill": AnyCodable(Fill.jsonSchema()),
                "fill-specializations": AnyCodable(SchemaProperty.array(items: FillSpecialization.jsonSchema())),
                "groups": AnyCodable(SchemaProperty.array(items: Group.jsonSchema())),
                "supported-platforms": AnyCodable(SupportedPlatforms.jsonSchema())
            ],
            required: ["groups", "supported-platforms"]
        )
    }
}

// MARK: - Fill
struct Fill: Codable, JSONSchemaConvertible {
    let automaticGradient: String?
    let solid: String?
    
    enum CodingKeys: String, CodingKey {
        case automaticGradient = "automatic-gradient"
        case solid
    }
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "automatic-gradient": AnyCodable(SchemaProperty.string()),
            "solid": AnyCodable(SchemaProperty.string())
        ])
    }
}

// MARK: - Group  
struct Group: Codable, JSONSchemaConvertible {
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
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "layers": AnyCodable(SchemaProperty.array(items: Layer.jsonSchema())),
            "position": AnyCodable(Position.jsonSchema()),
            "shadow": AnyCodable(Shadow.jsonSchema()),
            "translucency": AnyCodable(Translucency.jsonSchema()),
            "blur-material": AnyCodable(SchemaProperty.number()),
            "lighting": AnyCodable(SchemaProperty.string(enumValues: ["combined", "individual"])),
            "specular": AnyCodable(SchemaProperty.boolean()),
            "blend-mode": AnyCodable(SchemaProperty.string(enumValues: ["multiply", "darken"])),
            "hidden": AnyCodable(SchemaProperty.boolean())
        ], required: ["layers"])
    }
}

// MARK: - Layer
struct Layer: Codable, JSONSchemaConvertible {
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
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "name": AnyCodable(SchemaProperty.string()),
            "image-name": AnyCodable(SchemaProperty.string(enumValues: PromptBuilder.getAvailableAssets())),
            "position": AnyCodable(Position.jsonSchema()),
            "fill": AnyCodable(Fill.jsonSchema()),
            "hidden": AnyCodable(SchemaProperty.boolean())
        ], required: ["name", "image-name"])
    }
}

// MARK: - Position
struct Position: Codable, JSONSchemaConvertible {
    let scale: Double
    let translationInPoints: [Double]
    
    enum CodingKeys: String, CodingKey {
        case scale
        case translationInPoints = "translation-in-points"
    }
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "scale": AnyCodable(SchemaProperty.number()),
            "translation-in-points": AnyCodable(SchemaProperty.array(items: SchemaProperty.number()))
        ], required: ["scale", "translation-in-points"])
    }
}

// MARK: - Shadow
struct Shadow: Codable, JSONSchemaConvertible {
    let kind: String
    let opacity: Double
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "kind": AnyCodable(SchemaProperty.string(enumValues: ["neutral", "layer-color"])),
            "opacity": AnyCodable(SchemaProperty.number())
        ], required: ["kind", "opacity"])
    }
}

// MARK: - Translucency
struct Translucency: Codable, JSONSchemaConvertible {
    let enabled: Bool
    let value: Double
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "enabled": AnyCodable(SchemaProperty.boolean()),
            "value": AnyCodable(SchemaProperty.number())
        ], required: ["enabled", "value"])
    }
}

// MARK: - Supported Platforms
struct SupportedPlatforms: Codable, JSONSchemaConvertible {
    let circles: [String]?
    let squares: String?
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "circles": AnyCodable(SchemaProperty.array(items: SchemaProperty.string())),
            "squares": AnyCodable(SchemaProperty.string())
        ])
    }
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

struct FillSpecialization: Codable, JSONSchemaConvertible {
    let appearance: String?
    let idiom: String?
    let value: Fill
    
    static func jsonSchema() -> SchemaProperty {
        return .object(properties: [
            "appearance": AnyCodable(SchemaProperty.string(enumValues: ["light", "dark", "tinted"])),
            "idiom": AnyCodable(SchemaProperty.string(enumValues: ["square", "circle"])),
            "value": AnyCodable(Fill.jsonSchema())
        ], required: ["value"])
    }
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
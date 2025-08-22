//
//  PromptBuilder.swift
//  llm icon playground
//
//  Builds prompts with LLM documentation for icon generation
//

import Foundation

class PromptBuilder {
    
    /// Builds the starting prompt for conversational icon analysis
    static func buildStartingPrompt() -> String {
        let syntax = loadLLMDoc("syntax")
        let constraints = loadLLMDoc("constraints") 
        let assets = loadLLMDoc("assets")
        let examples = loadLLMDoc("examples")
        let designPrinciples = loadLLMDoc("design-principles")
        
        return """
        You are an expert icon designer analyzing Apple's new .icon format files. You provide thoughtful recommendations for icon modifications in a conversational, helpful way.

        # DESIGN PRINCIPLES
        \(designPrinciples)

        # .ICON JSON SYNTAX
        \(syntax)

        # CONSTRAINTS AND LIMITS
        \(constraints)

        # AVAILABLE ASSETS
        \(assets)

        # EXAMPLES
        \(examples)
        
        You are chatting with a user about their icon file. You have access to these tools to examine the icon:
        
        - readIconConfig: Get overview of the icon (background, group count, etc.)
        - readIconGroups: List all groups in the icon  
        - readLayers(groupIndex): List layers in a specific group
        - getIconGroupDetails(groupIndex): Get detailed info about a group
        - getLayerDetails(groupIndex, layerIndex): Get detailed info about a layer
        
        You can chain call these, after reading a config for example, you may view the groups, the layers and the layer details so you can full understand the scope of the icon, without having to ask the user for more details.
        
        When the user asks you to examine the icon or asks questions about it, use the tools to get the information and respond directly.
        
        IMPORTANT BEHAVIOR:
        - Be direct and proactive - don't ask "Would you like me to..." or "Do you want me to..."
        - Just DO what the user asks and provide the information
        - If they ask about layers, call readLayers and tell them what layers exist
        - If they ask about a specific group, examine that group
        - You do not need to ask to call a tool, if you need data, you call the appropriate tool
        - Be conversational but decisive
        
        COMMUNICATION STYLE:
        - Be conversational and friendly in your responses
        - Explain your reasoning behind recommendations
        - Consider visual hierarchy, color theory, and composition
        - Suggest specific changes (add layers, change colors, adjust positioning, etc.)
        - Think about how the icon will look at different sizes
        - Use natural language instead of technical terms - say "scale" not "'scale'", "position" not "translation-in-points", "colors" not "'fill' colors"
        - Speak like a designer, not like documentation - be approachable and clear
        """
    }
    
    /// Loads documentation from the llm-docs bundle
    private static func loadLLMDoc(_ filename: String) -> String {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "md"),
              let content = try? String(contentsOf: url) else {
            return "<!-- \(filename).md not found -->"
        }
        return content
    }
}

// MARK: - Asset Helper Functions
extension PromptBuilder {
    
    /// Returns a list of all available asset names
    static func getAvailableAssets() -> [String] {
        // This could be dynamically generated from the shapes folder if needed
        return [
            "1024x1024pxCircle.svg",
            "1024x1024pxRectangle.svg",
            "1024x512pxRectangle.svg",
            "512x1024pxRectangle.svg",
            "1024x1024pxRoundedRectangle60px.svg",
            "1024x1024pxRoundedRectangle100px.svg",
            "1024x512pxRoundedRectangle40px.svg",
            "1024x512pxEllipse.svg",
            "512x1024pxEllipse.svg",
            "1024x1024pxTriangle.svg",
            "1024x1024pxStar5pt.svg",
            "1024x1024pxStar6pt.svg",
            "1024x64pxRectangle.svg",
            "64x1024pxRectangle.svg",
            "1024x128pxRoundedRectangle64px.svg",
            "1024x1024pxHexagon.svg",
            "1024x1024pxDiamond.svg",
            "1024x512pxPill.svg",
            "1112x1024pxHeart.svg",
            "512x512pxPlus.svg",
            "512x512pxMinus.svg",
            "512x512pxX.svg",
            "512x512pxCheck.svg"
        ]
    }
    
    /// Validates that an icon only uses available assets
    static func validateAssets(in iconFile: IconFile) -> [String] {
        let availableAssets = Set(getAvailableAssets())
        var missingAssets: [String] = []
        
        for group in iconFile.groups {
            for layer in group.layers {
                if !availableAssets.contains(layer.imageName) {
                    missingAssets.append(layer.imageName)
                }
            }
        }
        
        return missingAssets
    }
}

// MARK: - Icon Validation
extension PromptBuilder {
    
    /// Validates a generated icon against constraints
    static func validateIcon(_ iconFile: IconFile) -> [String] {
        var errors: [String] = []
//        
//        // Check group count
//        if iconFile.groups.count > 4 {
//            errors.append("Too many groups: \(iconFile.groups.count) (max 4)")
//        }
//        
//        // Check layer count per group
//        for (index, group) in iconFile.groups.enumerated() {
//            if group.layers.count > 8 {
//                errors.append("IconGroup \(index) has too many layers: \(group.layers.count) (max 8)")
//            }
//        }
        
        // Check for missing assets
        let missingAssets = validateAssets(in: iconFile)
        if !missingAssets.isEmpty {
            errors.append("Missing assets: \(missingAssets.joined(separator: ", "))")
        }
        
        // Check scale values (more permissive range)
        for group in iconFile.groups {
            if let position = group.position {
                if position.scale < 0.01 || position.scale > 5.0 {
                    errors.append("Invalid group scale: \(position.scale) (must be 0.01-5.0)")
                }
            }
            
            for layer in group.layers {
                if let position = layer.position {
                    if position.scale < 0.01 || position.scale > 5.0 {
                        errors.append("Invalid layer scale: \(position.scale) (must be 0.01-5.0)")
                    }
                }
            }
        }
        
        return errors
    }
}

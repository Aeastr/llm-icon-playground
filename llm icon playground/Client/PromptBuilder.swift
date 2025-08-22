//
//  PromptBuilder.swift
//  llm icon playground
//
//  Builds prompts with LLM documentation for icon generation
//

import Foundation

class PromptBuilder {
    
    /// Builds the complete system prompt with all LLM documentation
    static func buildSystemPrompt() -> String {
        let syntax = loadLLMDoc("syntax")
        let constraints = loadLLMDoc("constraints") 
        let assets = loadLLMDoc("assets")
        let examples = loadLLMDoc("examples")
        let designPrinciples = loadLLMDoc("design-principles")
        
        return """
        You are an expert icon designer using Apple's .icon format. Create beautiful, layered icons that match user descriptions.

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
    
    /// Creates a complete prompt with system instructions and user request
    static func buildCompletePrompt(userDescription: String) -> String {
        let systemPrompt = buildSystemPrompt()
        
        return """
        \(systemPrompt)
        
        # DESIGN BRIEF
        Create an icon for: \(userDescription)
        
        Consider the visual metaphors, colors, and composition that would best represent this concept. Think about layer stacking, appropriate effects, and how the icon will look at different sizes.
        """
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
//                errors.append("Group \(index) has too many layers: \(group.layers.count) (max 8)")
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

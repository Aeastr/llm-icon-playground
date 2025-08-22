//
//  IconToolsManager.swift
//  llm icon playground
//
//  Manager for icon analysis tools that can be called by the LLM
//

import Foundation

struct IconToolsManager {
    let iconFileURL: URL
    let chatLogger: ChatLogger?
    
    func executeToolCall(_ toolCall: ToolCall) -> ToolResult {
        print("🔧 LLM called tool: \(toolCall.name) with parameters: \(toolCall.parameters)")
        
        do {
            let result: String
            
            switch toolCall.name {
            case "readIconConfig":
                let config = try IconAnalysisTools.readIconConfig(iconFileURL: iconFileURL)
                result = config.description
                
            case "readIconGroups":
                let groups = try IconAnalysisTools.readIconGroups(iconFileURL: iconFileURL)
                result = groups.isEmpty ? "No groups found" : groups.joined(separator: "\n")
                
            case "readLayers":
                guard let groupIndexStr = toolCall.parameters["groupIndex"] as? String,
                      let groupIndex = Int(groupIndexStr) else {
                    throw ToolError.invalidParameters("groupIndex must be a valid integer")
                }
                let layers = try IconAnalysisTools.readLayers(iconFileURL: iconFileURL, groupIndex: groupIndex)
                result = layers.isEmpty ? "No layers found in group \(groupIndex)" : layers.joined(separator: "\n")
                
            case "getLayerDetails":
                guard let groupIndexStr = toolCall.parameters["groupIndex"] as? String,
                      let layerIndexStr = toolCall.parameters["layerIndex"] as? String,
                      let groupIndex = Int(groupIndexStr),
                      let layerIndex = Int(layerIndexStr) else {
                    throw ToolError.invalidParameters("groupIndex and layerIndex must be valid integers")
                }
                let layerDetails = try IconAnalysisTools.getLayerDetails(iconFileURL: iconFileURL, groupIndex: groupIndex, layerIndex: layerIndex)
                result = layerDetails.description
                
            case "getIconGroupDetails":
                guard let groupIndexStr = toolCall.parameters["groupIndex"] as? String,
                      let groupIndex = Int(groupIndexStr) else {
                    throw ToolError.invalidParameters("groupIndex must be a valid integer")
                }
                let groupDetails = try IconAnalysisTools.getIconGroupDetails(iconFileURL: iconFileURL, groupIndex: groupIndex)
                result = groupDetails.description
                
            // MARK: - Icon Editing Tools
            case "updateIconBackground":
                guard let fillType = toolCall.parameters["fillType"] as? String else {
                    throw ToolError.invalidParameters("fillType is required")
                }
                let color = toolCall.parameters["color"] as? String
                result = try IconTools.updateIconBackground(
                    iconFileURL: iconFileURL,
                    fillType: fillType,
                    color: color
                )
                
            case "addIconFillSpecialization":
                guard let appearance = toolCall.parameters["appearance"] as? String,
                      let fillType = toolCall.parameters["fillType"] as? String else {
                    throw ToolError.invalidParameters("appearance and fillType are required")
                }
                let color = toolCall.parameters["color"] as? String
                result = try IconTools.addIconFillSpecialization(
                    iconFileURL: iconFileURL,
                    appearance: appearance,
                    fillType: fillType,
                    color: color
                )
                
            case "removeIconFillSpecialization":
                guard let appearance = toolCall.parameters["appearance"] as? String else {
                    throw ToolError.invalidParameters("appearance is required")
                }
                result = try IconTools.removeIconFillSpecialization(
                    iconFileURL: iconFileURL,
                    appearance: appearance
                )
                
            default:
                throw ToolError.unknownTool(toolCall.name)
            }
            
            chatLogger?.addToolCallMessage(name: toolCall.name, result: result)
            return ToolResult.success(result)
            
        } catch {
            let errorMsg = "Tool error: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            
            // Show failed tool call in chat with error message
            chatLogger?.addToolCallMessage(name: toolCall.name, result: "❌ \(errorMsg)")
            return ToolResult.error(errorMsg)
        }
    }
    
    static func getAvailableTools() -> [ToolDefinition] {
        return [
            ToolDefinition(
                name: "readIconConfig",
                description: "Read the top-level icon configuration including background fill, group count, and specializations",
                parameters: [:]
            ),
            ToolDefinition(
                name: "readIconGroups",
                description: "List all groups in the icon with their indices and names",
                parameters: [:]
            ),
            ToolDefinition(
                name: "readLayers",
                description: "List all layers in a specific group",
                parameters: [
                    "groupIndex": ParameterDefinition(type: "string", description: "The index of the group to read layers from")
                ]
            ),
            ToolDefinition(
                name: "getLayerDetails",
                description: "Get detailed information about a specific layer",
                parameters: [
                    "groupIndex": ParameterDefinition(type: "string", description: "The index of the group containing the layer"),
                    "layerIndex": ParameterDefinition(type: "string", description: "The index of the layer to examine")
                ]
            ),
            ToolDefinition(
                name: "getIconGroupDetails",
                description: "Get detailed information about a specific group",
                parameters: [
                    "groupIndex": ParameterDefinition(type: "string", description: "The index of the group to examine")
                ]
            ),
            
            // MARK: - Icon Editing Tools
            ToolDefinition(
                name: "updateIconBackground",
                description: "Change the main background fill of the icon",
                parameters: [
                    "fillType": ParameterDefinition(type: "string", description: "Type of fill: 'color' or 'gradient'"),
                    "color": ParameterDefinition(type: "string", description: "Hex color code (required for color fills)")
                ]
            ),
            ToolDefinition(
                name: "addIconFillSpecialization",
                description: "Add a background appearance variant for light/dark mode",
                parameters: [
                    "appearance": ParameterDefinition(type: "string", description: "Appearance mode: 'light' or 'dark'"),
                    "fillType": ParameterDefinition(type: "string", description: "Type of fill: 'color' or 'gradient'"),
                    "color": ParameterDefinition(type: "string", description: "Hex color code (required for color fills)")
                ]
            ),
            ToolDefinition(
                name: "removeIconFillSpecialization",
                description: "Remove a background appearance variant",
                parameters: [
                    "appearance": ParameterDefinition(type: "string", description: "Appearance mode to remove: 'light' or 'dark'")
                ]
            )
        ]
    }
}

// MARK: - Tool System Types

struct ToolCall {
    let name: String
    let parameters: [String: Any]
}

enum ToolResult {
    case success(String)
    case error(String)
}

struct ToolDefinition {
    let name: String
    let description: String
    let parameters: [String: ParameterDefinition]
}

struct ParameterDefinition {
    let type: String
    let description: String
}

enum ToolError: LocalizedError {
    case unknownTool(String)
    case invalidParameters(String)
    
    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool: \(name)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        }
    }
}

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
                
            case "readGroups":
                let groups = try IconAnalysisTools.readGroups(iconFileURL: iconFileURL)
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
                
            case "getGroupDetails":
                guard let groupIndexStr = toolCall.parameters["groupIndex"] as? String,
                      let groupIndex = Int(groupIndexStr) else {
                    throw ToolError.invalidParameters("groupIndex must be a valid integer")
                }
                let groupDetails = try IconAnalysisTools.getGroupDetails(iconFileURL: iconFileURL, groupIndex: groupIndex)
                result = groupDetails.description
                
            default:
                throw ToolError.unknownTool(toolCall.name)
            }
            
            chatLogger?.addSystemMessage("✅ Tool \(toolCall.name) returned: \(String(result.prefix(300)))\(result.count > 300 ? "..." : "")")
            return ToolResult.success(result)
            
        } catch {
            let errorMsg = "Tool error: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
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
                name: "readGroups",
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
                name: "getGroupDetails",
                description: "Get detailed information about a specific group",
                parameters: [
                    "groupIndex": ParameterDefinition(type: "string", description: "The index of the group to examine")
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
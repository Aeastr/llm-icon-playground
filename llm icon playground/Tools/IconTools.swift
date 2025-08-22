//
//  IconTools.swift
//  llm icon playground
//
//  Icon-level editing tools for modifying .icon files
//

import Foundation

/// Tools for editing icon-level properties (background, specializations, etc.)
struct IconTools {
    
    /// Updates the main background fill of the icon
    /// - Parameters:
    ///   - iconFileURL: URL to the .icon file
    ///   - fillType: "color" or "gradient"
    ///   - color: Hex color (for solid fills)
    ///   - gradient: Gradient definition (for gradient fills)
    /// - Returns: Success message or error
    static func updateIconBackground(
        iconFileURL: URL,
        fillType: String,
        color: String? = nil,
        gradient: [String: Any]? = nil
    ) throws -> String {
        
        // 1. Load and parse the current icon
        var iconFile = try loadIconFile(from: iconFileURL)
        
        // 2. Create new fill based on type
        let newFill: Fill
        switch fillType.lowercased() {
        case "color", "solid":
            guard let color = color else {
                throw IconToolError.invalidParameters("Color fills require a 'color' parameter. You provided fillType='color' but no color parameter.")
            }
            newFill = Fill(automaticGradient: nil, solid: color)
            
        case "automatic":
            newFill = Fill(automaticGradient: nil, solid: "automatic")
            
        case "system-light":
            newFill = Fill(automaticGradient: nil, solid: "system-light")
            
        case "system-dark":
            newFill = Fill(automaticGradient: nil, solid: "system-dark")
            
        case "gradient", "automatic-gradient":
            guard let color = color else {
                throw IconToolError.invalidParameters("Automatic gradient fills require a 'color' parameter for the base color.")
            }
            newFill = Fill(automaticGradient: color, solid: nil)
            
        default:
            throw IconToolError.invalidParameters("Invalid fillType '\(fillType)'. Valid options: 'color'/'solid' (with color), 'automatic', 'system-light', 'system-dark', 'automatic-gradient' (with color). You provided: '\(fillType)'")
        }
        
        // 3. Update the icon's background fill
        iconFile.fill = newFill
        
        // 4. Save the modified icon back to file
        try saveIconFile(iconFile, to: iconFileURL)
        
        return "Successfully updated icon background to \(fillType): \(color ?? "gradient")"
    }
    
    /// Adds a fill specialization for appearance variants (light/dark mode)
    /// - Parameters:
    ///   - iconFileURL: URL to the .icon file
    ///   - appearance: "light" or "dark"
    ///   - fillType: "color" or "gradient"
    ///   - color: Hex color (for solid fills)
    ///   - gradient: Gradient definition (for gradient fills)
    /// - Returns: Success message or error
    static func addIconFillSpecialization(
        iconFileURL: URL,
        appearance: String,
        fillType: String,
        color: String? = nil,
        gradient: [String: Any]? = nil
    ) throws -> String {
        
        // 1. Validate appearance parameter
        guard ["light", "dark"].contains(appearance.lowercased()) else {
            throw IconToolError.invalidParameters("Invalid appearance '\(appearance)'. Must be 'light' or 'dark' for appearance variants. You provided: '\(appearance)'")
        }
        
        // 2. Load and parse the current icon
        var iconFile = try loadIconFile(from: iconFileURL)
        
        // 3. Create new fill
        let newFill: Fill
        switch fillType.lowercased() {
        case "color", "solid":
            guard let color = color else {
                throw IconToolError.invalidParameters("Color fills require a 'color' parameter. You provided fillType='color' but no color parameter.")
            }
            newFill = Fill(automaticGradient: nil, solid: color)
            
        case "automatic":
            newFill = Fill(automaticGradient: nil, solid: "automatic")
            
        case "system-light":
            newFill = Fill(automaticGradient: nil, solid: "system-light")
            
        case "system-dark":
            newFill = Fill(automaticGradient: nil, solid: "system-dark")
            
        case "gradient", "automatic-gradient":
            guard let color = color else {
                throw IconToolError.invalidParameters("Automatic gradient fills require a 'color' parameter for the base color.")
            }
            newFill = Fill(automaticGradient: color, solid: nil)
            
        default:
            throw IconToolError.invalidParameters("Invalid fillType '\(fillType)'. Valid options: 'color'/'solid' (with color), 'automatic', 'system-light', 'system-dark', 'automatic-gradient' (with color). You provided: '\(fillType)'")
        }
        
        // 4. Create specialization
        let specialization = FillSpecialization(
            appearance: appearance.lowercased(),
            idiom: nil, // No device targeting for basic appearance variants
            value: newFill
        )
        
        // 5. Add or update specializations array
        if iconFile.fillSpecializations == nil {
            iconFile.fillSpecializations = []
        }
        
        // Remove existing specialization for this appearance if it exists
        iconFile.fillSpecializations?.removeAll { $0.appearance == appearance.lowercased() }
        
        // Add new specialization
        iconFile.fillSpecializations?.append(specialization)
        
        // 6. Save the modified icon
        try saveIconFile(iconFile, to: iconFileURL)
        
        return "Successfully added \(appearance) mode background specialization"
    }
    
    /// Removes a fill specialization for a specific appearance
    /// - Parameters:
    ///   - iconFileURL: URL to the .icon file
    ///   - appearance: "light" or "dark"
    /// - Returns: Success message or error
    static func removeIconFillSpecialization(
        iconFileURL: URL,
        appearance: String
    ) throws -> String {
        
        // 1. Validate appearance parameter
        guard ["light", "dark"].contains(appearance.lowercased()) else {
            throw IconToolError.invalidParameters("Invalid appearance '\(appearance)'. Must be 'light' or 'dark' for appearance variants. You provided: '\(appearance)'")
        }
        
        // 2. Load and parse the current icon
        var iconFile = try loadIconFile(from: iconFileURL)
        
        // 3. Remove specialization if it exists
        guard var specializations = iconFile.fillSpecializations else {
            return "No fill specializations found to remove"
        }
        
        let originalCount = specializations.count
        specializations.removeAll { $0.appearance == appearance.lowercased() }
        
        if specializations.count == originalCount {
            return "No \(appearance) mode specialization found to remove"
        }
        
        // 4. Update icon (set to nil if empty)
        iconFile.fillSpecializations = specializations.isEmpty ? nil : specializations
        
        // 5. Save the modified icon
        try saveIconFile(iconFile, to: iconFileURL)
        
        return "Successfully removed \(appearance) mode background specialization"
    }
}

// MARK: - Helper Functions

extension IconTools {
    
    /// Loads an icon file from disk and parses it
    private static func loadIconFile(from url: URL) throws -> IconFile {
        print("🔍 Loading icon file from: \(url.path)")
        print("🔍 File exists: \(FileManager.default.fileExists(atPath: url.path))")
        print("🔍 URL is file URL: \(url.isFileURL)")
        print("🔍 URL scheme: \(url.scheme ?? "nil")")
        
        // .icon files are actually packages/bundles, so we need to read icon.json inside
        let iconJsonURL = url.appendingPathComponent("icon.json")
        print("🔍 Looking for icon.json at: \(iconJsonURL.path)")
        print("🔍 icon.json exists: \(FileManager.default.fileExists(atPath: iconJsonURL.path))")
        
        // Try to create backup before modifying (but don't fail if we can't)
        do {
            try createBackup(of: iconJsonURL)
        } catch {
            print("⚠️ Warning: Could not create backup file: \(error.localizedDescription)")
            // Continue anyway - editing is more important than backup
        }
        
        do {
            let data = try Data(contentsOf: iconJsonURL)
            let decoder = JSONDecoder()
            return try decoder.decode(IconFile.self, from: data)
        } catch {
            print("❌ Failed to load icon file: \(error)")
            print("❌ Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                print("❌ NSError domain: \(nsError.domain)")
                print("❌ NSError code: \(nsError.code)")
                print("❌ NSError userInfo: \(nsError.userInfo)")
            }
            throw IconToolError.parseError("Failed to load icon.json from \(iconJsonURL.path): \(error.localizedDescription)")
        }
    }
    
    /// Saves an icon file back to disk with proper formatting
    private static func saveIconFile(_ iconFile: IconFile, to url: URL) throws {
        // .icon files are packages, so we need to save to icon.json inside
        let iconJsonURL = url.appendingPathComponent("icon.json")
        print("💾 Saving icon file to: \(iconJsonURL.path)")
        print("💾 Parent directory exists: \(FileManager.default.fileExists(atPath: iconJsonURL.deletingLastPathComponent().path))")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try encoder.encode(iconFile)
            try data.write(to: iconJsonURL)
            print("✅ Successfully saved icon file")
        } catch {
            print("❌ Failed to save icon file: \(error)")
            print("❌ Error type: \(type(of: error))")
            if let nsError = error as NSError? {
                print("❌ NSError domain: \(nsError.domain)")
                print("❌ NSError code: \(nsError.code)")
                print("❌ NSError userInfo: \(nsError.userInfo)")
            }
            throw IconToolError.parseError("Failed to save icon.json to \(iconJsonURL.path): \(error.localizedDescription)")
        }
    }
    
    /// Creates a backup of the original file before editing
    private static func createBackup(of url: URL) throws {
        let backupURL = url.appendingPathExtension("backup")
        
        // Only create backup if it doesn't already exist
        if !FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.copyItem(at: url, to: backupURL)
        }
    }
}

// MARK: - Errors

enum IconToolError: LocalizedError {
    case invalidParameters(String)
    case fileNotFound(String)
    case parseError(String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        }
    }
}
//
//  IconPreviewManager.swift
//  llm icon playground
//
//  Observable manager for icon preview updates
//

import SwiftUI
import Foundation
import QuickLookThumbnailing
import AppKit

@Observable
class IconPreviewManager {
    var currentThumbnail: NSImage?
    var iconURL: URL?
    
    func setIconURL(_ url: URL) {
        iconURL = url
        generateThumbnail(for: url)
    }
    
    func refreshPreview() {
        print("🔄 IconPreviewManager.refreshPreview() called")
        print("🔄 Current iconURL: \(iconURL?.path ?? "nil")")
        if let url = iconURL {
            print("🔄 Generating new thumbnail for: \(url.lastPathComponent)")
            // Add a small delay to let the file system catch up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.generateThumbnail(for: url)
            }
        } else {
            print("🔄 No iconURL set, skipping refresh")
        }
    }
    
    func forceRefresh() {
        print("🔄 Force refresh requested")
        if let url = iconURL {
            generateThumbnail(for: url)
        }
    }
    
    private func generateThumbnail(for url: URL) {
        let size = CGSize(width: 300, height: 300)
        let scale = NSScreen.main?.backingScaleFactor ?? 1.0
        
        // Try to force cache invalidation by touching the parent directory
        let parentURL = url.deletingLastPathComponent()
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: parentURL.path)
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .all
        )
        
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] thumbnail, error in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    print("🔄 Successfully generated new thumbnail")
                    let newImage = NSImage(cgImage: thumbnail.cgImage, size: size)
                    print("🔄 Setting currentThumbnail (old: \(self?.currentThumbnail != nil ? "exists" : "nil"), new: exists)")
                    self?.currentThumbnail = newImage
                    print("🔄 currentThumbnail updated, should trigger UI refresh")
                } else {
                    print("🔄 Thumbnail generation failed, using fallback: \(error?.localizedDescription ?? "unknown error")")
                    // Fallback to file type icon
                    self?.currentThumbnail = NSWorkspace.shared.icon(forFile: url.path)
                }
            }
        }
    }
}
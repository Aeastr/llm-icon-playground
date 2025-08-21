//
//  ContentView.swift
//  llm icon playground
//
//  Created by Aether on 21/08/2025.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var iconName = "TestIcon"
    @State private var outputDirectory: URL?
    @State private var showingDirectoryPicker = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Icon Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Icon Name:")
                TextField("Enter icon name", text: $iconName)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Output Directory:")
                HStack {
                    Text(outputDirectory?.lastPathComponent ?? "No directory selected")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Choose...") {
                        showingDirectoryPicker = true
                    }
                }
            }
            
            Button("Generate Test Icon") {
                generateTestIcon()
            }
            .disabled(outputDirectory == nil || iconName.isEmpty)
            .buttonStyle(.borderedProminent)
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start accessing security-scoped resource
                    _ = url.startAccessingSecurityScopedResource()
                    outputDirectory = url
                    statusMessage = "Directory selected: \(url.lastPathComponent)"
                }
            case .failure(let error):
                statusMessage = "Error selecting directory: \(error.localizedDescription)"
            }
        }
    }
    
    private func generateTestIcon() {
        guard let outputDir = outputDirectory else { return }
        
        // Create a simple test icon
        let testIcon = IconFile.simple(
            fill: Fill(
                automaticGradient: "extended-srgb:0.2,0.6,1.0,1.0",
                solid: nil
            ),
            groups: [
                Group.simple(layers: [
                    Layer.simple(
                        name: "Background",
                        imageName: "1024x1024pxCircle.svg",
                        position: Position(
                            scale: 0.8,
                            translationInPoints: [0, 0]
                        )
                    )
                ])
            ]
        )
        
        do {
            try IconGenerator.createIconFile(
                iconData: testIcon,
                outputDirectory: outputDir,
                iconName: iconName
            )
            statusMessage = "Icon generated successfully!"
        } catch {
            statusMessage = "Error generating icon: \(error.localizedDescription)"
        }
        
        // Stop accessing security-scoped resource
        outputDir.stopAccessingSecurityScopedResource()
    }
}

#Preview {
    ContentView()
}

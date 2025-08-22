//
//  NewIconSheet.swift
//  llm icon playground
//
//  Sheet for creating new .icon files
//

import SwiftUI
import UniformTypeIdentifiers

struct NewIconSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var iconName = ""
    @State private var selectedDirectory: URL?
    @State private var showingDirectoryPicker = false
    @State private var isCreating = false
    @State private var errorMessage = ""
    
    let onIconCreated: (URL) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Icon Name:")
                    TextField("Enter icon name", text: $iconName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save Location:")
                    HStack {
                        Text(selectedDirectory?.lastPathComponent ?? "No directory selected")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Choose...") {
                            showingDirectoryPicker = true
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Icon File")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNewIcon()
                    }
                    .disabled(!canCreate || isCreating)
                }
            }
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedDirectory = url
                }
            case .failure(let error):
                errorMessage = "Error selecting directory: \(error.localizedDescription)"
            }
        }
    }
    
    private var canCreate: Bool {
        !iconName.isEmpty && selectedDirectory != nil
    }
    
    private func createNewIcon() {
        guard let directory = selectedDirectory else { return }
        
        isCreating = true
        errorMessage = ""
        
        let iconFileName = iconName.hasSuffix(".icon") ? iconName : "\(iconName).icon"
        let iconFileURL = directory.appendingPathComponent(iconFileName)
        
        // Create a simple default icon structure
        let defaultIcon = IconFile.simple(
            fill: Fill(
                automaticGradient: "display-p3:0.5,0.5,0.5,1.0",
                solid: nil
            ),
            groups: [
                Group.simple(layers: [
                    Layer.simple(
                        name: "Background",
                        imageName: "1024x1024pxRoundedRectangle100px.svg",
                        position: Position(
                            scale: 1.0,
                            translationInPoints: [0, 0]
                        )
                    )
                ])
            ]
        )
        
        do {
            try IconGenerator.createIconFile(
                iconData: defaultIcon,
                outputDirectory: directory,
                iconName: iconName,
                useModelFolder: false
            )
            
            onIconCreated(iconFileURL)
            dismiss()
        } catch {
            errorMessage = "Failed to create icon file: \(error.localizedDescription)"
            isCreating = false
        }
    }
}

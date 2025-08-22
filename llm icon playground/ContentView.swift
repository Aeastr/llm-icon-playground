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
    @State private var iconDescription = ""
    @State private var outputDirectory: URL?
    @State private var showingDirectoryPicker = false
    @State private var statusMessage = ""
    @State private var isAccessingSecurityScopedResource = false
    @State private var apiKey = ""
    @State private var isGenerating = false
    @State private var showingAPIKeyField = false
    @State private var selectedModel = "gemini-2.5-flash"
    @State private var availableModels: [String] = GeminiClient.commonModels
    @State private var showingFallbackAlert = false
    @State private var fallbackAlertTitle = ""
    @State private var fallbackAlertMessage = ""
    
    private let userDefaults = UserDefaults.standard
    private let outputDirectoryKey = "outputDirectory"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Icon Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // API Key Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Gemini API Key:")
                    Spacer()
                    if GeminiClient.hasValidAPIKey() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Button("Change") {
                            showingAPIKeyField.toggle()
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button("Configure") {
                            showingAPIKeyField = true
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                if showingAPIKeyField {
                    HStack {
                        SecureField("Enter Gemini API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                        Button("Save") {
                            saveAPIKey()
                        }
                        .disabled(apiKey.isEmpty)
                        Button("Cancel") {
                            showingAPIKeyField = false
                            apiKey = ""
                        }
                    }
                }
            }
            
            // Model Selection
            if GeminiClient.hasValidAPIKey() {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Model:")
                        Spacer()
                        Button("Refresh Models") {
                            refreshModels()
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            Divider()
            
            // Icon Generation Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Icon Description:")
                TextField("Describe your icon (e.g., 'Coffee app with steam')", text: $iconDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
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
            
            HStack(spacing: 10) {
                Button("Generate AI Icon") {
                    generateAIIcon()
                }
                .disabled(!canGenerateIcon() || isGenerating)
                .buttonStyle(.borderedProminent)
                
                Button("Test Gemini") {
                    testGemini()
                }
                .disabled(!GeminiClient.hasValidAPIKey() || isGenerating)
                .buttonStyle(.bordered)
                
                Button("Test Simple Icon") {
                    generateTestIcon()
                }
                .disabled(outputDirectory == nil || iconName.isEmpty || isGenerating)
                .buttonStyle(.bordered)
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(statusMessage.contains("Error") ? .red : .green)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating icon...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadSavedDirectory()
            if GeminiClient.hasValidAPIKey() {
                refreshModels()
            }
            
            // Listen for structured output fallback notifications
            NotificationCenter.default.addObserver(
                forName: Notification.Name("StructuredOutputFallback"),
                object: nil,
                queue: .main
            ) { notification in
                if let error = notification.object as? GeminiError,
                   let details = error.fallbackDetails {
                    fallbackAlertTitle = "Fallback to Unstructured Mode"
                    fallbackAlertMessage = details
                    showingFallbackAlert = true
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
                    // Stop previous resource access if any
                    if isAccessingSecurityScopedResource, let currentDir = outputDirectory {
                        currentDir.stopAccessingSecurityScopedResource()
                    }
                    
                    // Start accessing security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        outputDirectory = url
                        isAccessingSecurityScopedResource = true
                        saveDirectory(url)
                        statusMessage = "Directory selected: \(url.lastPathComponent)"
                    } else {
                        statusMessage = "Failed to access selected directory"
                    }
                }
            case .failure(let error):
                statusMessage = "Error selecting directory: \(error.localizedDescription)"
            }
        }
        .alert(fallbackAlertTitle, isPresented: $showingFallbackAlert) {
            Button("OK") { }
        } message: {
            Text(fallbackAlertMessage)
        }
    }
    
    private func generateTestIcon() {
        guard let outputDir = outputDirectory else { return }
        
        // Create a simple test icon with proper background fill
        let testIcon = IconFile.simple(
            fill: Fill(
                automaticGradient: "display-p3:0.97049,0.31165,0.19665,1.00000",
                solid: nil
            ),
            groups: [
                Group.simple(layers: [
                    Layer.simple(
                        name: "Circle",
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
        
        // Don't stop accessing - keep permissions for next use
    }
    
    private func canGenerateIcon() -> Bool {
        return GeminiClient.hasValidAPIKey() && 
               !iconDescription.isEmpty && 
               !iconName.isEmpty && 
               outputDirectory != nil
    }
    
    private func saveAPIKey() {
        if GeminiClient.setAPIKey(apiKey) {
            statusMessage = "API key saved securely"
            showingAPIKeyField = false
            apiKey = ""
        } else {
            statusMessage = "Error: Failed to save API key"
        }
    }
    
    private func generateAIIcon() {
        guard let outputDir = outputDirectory else { return }
        guard let geminiClient = GeminiClient.client(model: selectedModel) else {
            statusMessage = "Error: No valid API key"
            return
        }
        
        isGenerating = true
        statusMessage = "Generating icon with AI..."
        
        let systemPrompt = PromptBuilder.buildSystemPrompt()
        
        geminiClient.generateIcon(description: iconDescription, systemPrompt: systemPrompt) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                
                switch result {
                case .success(let iconFile):
                    // Validate the generated icon
                    let validationErrors = PromptBuilder.validateIcon(iconFile)
                    if !validationErrors.isEmpty {
                        self.statusMessage = "Error: Generated icon has issues: \(validationErrors.joined(separator: ", "))"
                        return
                    }
                    
                    // Try to create the icon file
                    do {
                        try IconGenerator.createIconFile(
                            iconData: iconFile,
                            outputDirectory: outputDir,
                            iconName: self.iconName
                        )
                        self.statusMessage = "AI icon generated successfully! 🎉"
                    } catch {
                        self.statusMessage = "Error creating icon file: \(error.localizedDescription)"
                    }
                    
                case .failure(let error):
                    self.statusMessage = "Error generating icon: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func testGemini() {
        guard let geminiClient = GeminiClient.shared else {
            statusMessage = "Error: No valid API key"
            return
        }
        
        isGenerating = true
        statusMessage = "Testing Gemini connection..."
        
        geminiClient.generateText(prompt: "Say hello and return a simple JSON object with one property called 'test' with value 'success'.") { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                
                switch result {
                case .success(let response):
                    self.statusMessage = "✅ Gemini working! Response: \(response.prefix(100))..."
                case .failure(let error):
                    self.statusMessage = "❌ Gemini test failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func refreshModels() {
        GeminiClient.getAvailableModels { result in
            switch result {
            case .success(let models):
                self.availableModels = models
                print("📡 Available models: \(models)")
            case .failure(let error):
                print("❌ Failed to fetch models: \(error)")
                // Keep using fallback models
            }
        }
    }
    
    private func loadSavedDirectory() {
        if let bookmarkData = userDefaults.data(forKey: outputDirectoryKey) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if !isStale {
                    // Start accessing the security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        outputDirectory = url
                        isAccessingSecurityScopedResource = true
                        statusMessage = "Using saved directory: \(url.lastPathComponent)"
                    } else {
                        statusMessage = "Could not access saved directory"
                    }
                } else {
                    statusMessage = "Saved directory bookmark is stale, please reselect"
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
                statusMessage = "Failed to load saved directory"
            }
        }
    }
    
    private func saveDirectory(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(bookmarkData, forKey: outputDirectoryKey)
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

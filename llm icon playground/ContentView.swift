//
//  ContentView.swift
//  llm icon playground
//
//  Created by Aether on 21/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let iconFile = UTType(filenameExtension: "icon", conformingTo: .package)!
}

struct ContentView: View {
    @State private var iconName = ""
    @State private var iconDescription = ""
    @State private var selectedIconFile: URL?
    @State private var showingIconFilePicker = false
    @State private var showingNewIconSheet = false
    @State private var statusMessage = ""
    @State private var isAccessingSecurityScopedResource = false
    @State private var apiKey = ""
    @State private var isGenerating = false
    @State private var showingAPIKeyField = false
    @AppStorage("selectedModel") var selectedModel = "gemini-2.5-flash"
    @AppStorage("useModelFolder") var useModelFolder = true
    @State private var availableModels: [String] = GeminiClient.commonModels
    @State private var showingFallbackAlert = false
    @State private var fallbackAlertTitle = ""
    @State private var fallbackAlertMessage = ""
    @State private var showChat = true
    @State private var chatLogger = ChatLogger()
    private let userDefaults = UserDefaults.standard
    private let selectedIconFileKey = "selectedIconFile"
    
    var body: some View {
        NavigationStack{
                ScrollView{
                    VStack(spacing: 15) {
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Icon File:")
                            HStack {
                                Text(selectedIconFile?.lastPathComponent ?? "No .icon file selected")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Open...") {
                                    showingIconFilePicker = true
                                }
                                Button("New...") {
                                    showingNewIconSheet = true
                                }
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        loadSavedIconFile()
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
                        isPresented: $showingIconFilePicker,
                        allowedContentTypes: [.iconFile, .package, .folder],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                // Stop previous resource access if any
                                if isAccessingSecurityScopedResource, let currentFile = selectedIconFile {
                                    currentFile.stopAccessingSecurityScopedResource()
                                }
                                
                                // Start accessing security-scoped resource
                                if url.startAccessingSecurityScopedResource() {
                                    selectedIconFile = url
                                    isAccessingSecurityScopedResource = true
                                    saveIconFile(url)
                                    statusMessage = "Icon file selected: \(url.lastPathComponent)"
                                } else {
                                    statusMessage = "Failed to access selected icon file"
                                }
                            }
                        case .failure(let error):
                            statusMessage = "Error selecting icon file: \(error.localizedDescription)"
                        }
                    }
                    .alert(fallbackAlertTitle, isPresented: $showingFallbackAlert) {
                        Button("OK") { }
                    } message: {
                        Text(fallbackAlertMessage)
                    }
            }
            .navigationTitle("Icon Experiment")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    let hasKey = GeminiClient.hasValidAPIKey()
                    Button(hasKey ? "Change API Key" : "Set API Key", systemImage: hasKey ? "key.fill" : "key.slash.fill") {
                        showingAPIKeyField.toggle()
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    
                        Button("Analyze Icon") {
                            generateAIIcon()
                        }
                        .disabled(!canGenerateIcon() || isGenerating)
                }
            }
            .inspector(isPresented: $showChat) {
                ChatView(chatLogger: chatLogger)
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 5){
                            TextField("Describe your changes.", text: $iconDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                            
                            
                            // Model Selection
                            if GeminiClient.hasValidAPIKey() {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack{
                                        Picker("Model",selection: $selectedModel) {
                                            ForEach(availableModels, id: \.self) { model in
                                                Text(model).tag(model)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                    .inspectorColumnWidth(min: 200, ideal: 300, max: 400)
            }
        }
        .sheet(isPresented: $showingAPIKeyField) {
            VStack {
                Text("API Key")
                    .font(.headline)
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
            .padding()
        }
        .sheet(isPresented: $showingNewIconSheet) {
            NewIconSheet(onIconCreated: { url in
                selectedIconFile = url
                statusMessage = "New icon file created: \(url.lastPathComponent)"
            })
        }
    }
    
    
    private func finalIconName() -> String {
        return iconName.isEmpty ? iconDescription.isEmpty ? "Icon" : iconDescription : iconName
    }
    
    private func fileNameWithModel() -> String {
        let baseName = finalIconName().replacingOccurrences(of: " ", with: "_")
        let model = selectedModel.replacingOccurrences(of: " ", with: "_")
        return "\(baseName)-\(model)"
    }
    
    
    private func canGenerateIcon() -> Bool {
        return GeminiClient.hasValidAPIKey() && 
               !iconDescription.isEmpty &&
               selectedIconFile != nil
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
        guard let iconFile = selectedIconFile else { return }
        guard let geminiClient = GeminiClient.client(model: selectedModel) else {
            statusMessage = "Error: No valid API key"
            return
        }
        
        isGenerating = true
        statusMessage = "Generating icon with AI..."
        
        let systemPrompt = PromptBuilder.buildSystemPrompt()
        
        geminiClient.analyzeIcon(iconFileURL: iconFile, userRequest: iconDescription, chatLogger: chatLogger) { result in
            DispatchQueue.main.async {
                self.isGenerating = false
                
                switch result {
                case .success(let analysis):
                    self.statusMessage = "Icon analysis completed! 🎉"
                    self.chatLogger.addSystemMessage("Analysis complete. Review recommendations in chat log.")
                    
                case .failure(let error):
                    self.statusMessage = "Error analyzing icon: \(error.localizedDescription)"
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
    
    private func loadSavedIconFile() {
        if let bookmarkData = userDefaults.data(forKey: selectedIconFileKey) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if !isStale {
                    // Start accessing the security-scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        selectedIconFile = url
                        isAccessingSecurityScopedResource = true
                    } else {
                        statusMessage = "Could not access saved icon file"
                    }
                } else {
                    statusMessage = "Saved icon file bookmark is stale, please reselect"
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
                statusMessage = "Failed to load saved icon file"
            }
        }
    }
    
    private func saveIconFile(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(bookmarkData, forKey: selectedIconFileKey)
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
}

#Preview {
    ContentView()
}


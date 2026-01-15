/*
 * FileEditorView.swift - File Editor UI
 * iOS 26.1 Jailbreak for iPhone Air
 * 
 * Edit files with root privileges using real exploit
 */

import SwiftUI

struct FileEditorView: View {
    let filePath: String
    @ObservedObject var fileManager: FileSystemManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var isLoading: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var showingSaveConfirm: Bool = false
    @State private var showingDiscardConfirm: Bool = false
    @State private var isReadOnly: Bool = false
    @State private var fileInfo: FileInfo?
    
    private var fileName: String {
        (filePath as NSString).lastPathComponent
    }
    
    private var hasChanges: Bool {
        content != originalContent
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    editorView
                }
            }
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if !isReadOnly {
                        Button("Save") {
                            saveFile()
                        }
                        .disabled(!hasChanges || isSaving)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .confirmationDialog("Unsaved Changes", isPresented: $showingDiscardConfirm, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
        .onAppear {
            loadFile()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading file...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load file")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadFile()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Editor View
    
    private var editorView: some View {
        VStack(spacing: 0) {
            // File info bar
            fileInfoBar
            
            // Editor
            if isReadOnly {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.systemBackground))
            } else {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Status bar
            statusBar
        }
    }
    
    // MARK: - File Info Bar
    
    private var fileInfoBar: some View {
        HStack {
            Text(filePath)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            if isReadOnly {
                Label("Read Only", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if hasChanges {
                Text("Modified")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            if let info = fileInfo {
                Text("Size: \(formatSize(info.size))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Lines: \(content.components(separatedBy: "\n").count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Actions
    
    private func loadFile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Check if file is readable
            guard ExploitBridge.isExploitActive() else {
                await MainActor.run {
                    errorMessage = "Exploit not active"
                    isLoading = false
                }
                return
            }
            
            // Get file info
            if let info = ExploitBridge.getFileInfo(filePath) {
                await MainActor.run {
                    fileInfo = info
                    // Check if writable
                    isReadOnly = !info.permissions.contains("w")
                }
            }
            
            // Read file content
            if let fileContent = ExploitBridge.readFile(filePath) {
                await MainActor.run {
                    content = fileContent
                    originalContent = fileContent
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Failed to read file"
                    isLoading = false
                }
            }
        }
    }
    
    private func saveFile() {
        guard !isReadOnly else { return }
        
        isSaving = true
        
        Task {
            let success = ExploitBridge.writeFile(filePath, contents: content)
            
            await MainActor.run {
                isSaving = false
                
                if success {
                    originalContent = content
                    fileManager.refresh()
                    dismiss()
                } else {
                    errorMessage = "Failed to save file"
                    showingError = true
                }
            }
        }
    }
    
    private func handleCancel() {
        if hasChanges {
            showingDiscardConfirm = true
        } else {
            dismiss()
        }
    }
    
    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Hex Viewer (for binary files)

struct HexViewerView: View {
    let filePath: String
    
    @State private var hexData: [(offset: Int, hex: String, ascii: String)] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(hexData, id: \.offset) { row in
                            HStack(spacing: 8) {
                                Text(String(format: "%08X", row.offset))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(row.hex)
                                    .font(.system(.caption, design: .monospaced))
                                
                                Text(row.ascii)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadHexData()
        }
    }
    
    private func loadHexData() {
        Task {
            guard let data = ExploitBridge.readFileData(filePath) else {
                await MainActor.run {
                    errorMessage = "Failed to read file"
                    isLoading = false
                }
                return
            }
            
            let bytesPerRow = 16
            var tempRows: [(offset: Int, hex: String, ascii: String)] = []
            
            for offset in stride(from: 0, to: min(data.count, 4096), by: bytesPerRow) {
                let endIndex = min(offset + bytesPerRow, data.count)
                let rowData = data[offset..<endIndex]
                
                let hex = rowData.map { String(format: "%02X", $0) }.joined(separator: " ")
                let ascii = rowData.map { byte -> String in
                    if byte >= 32 && byte < 127 {
                        return String(UnicodeScalar(byte))
                    } else {
                        return "."
                    }
                }.joined()
                
                tempRows.append((offset: offset, hex: hex, ascii: ascii))
            }
            
            let finalRows = tempRows
            await MainActor.run {
                hexData = finalRows
                isLoading = false
            }
        }
    }
}

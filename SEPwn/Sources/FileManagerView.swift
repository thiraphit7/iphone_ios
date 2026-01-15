/*
 * FileManagerView.swift - File Manager UI
 * iOS 26.1 Jailbreak for iPhone Air
 * 
 * Full file system access using real exploit
 * Supports: browse, create, edit, delete, search
 */

import SwiftUI

struct FileManagerView: View {
    @ObservedObject var jailbreakManager: JailbreakManager
    @StateObject private var fileManager = FileSystemManager()
    
    @State private var showingNewFileSheet = false
    @State private var showingNewFolderSheet = false
    @State private var showingSearchSheet = false
    @State private var showingFileEditor = false
    @State private var selectedFile: FileItem?
    @State private var showingActionSheet = false
    @State private var showingDeleteConfirm = false
    @State private var showingRenameSheet = false
    @State private var showingPermissionsSheet = false
    @State private var newItemName = ""
    @State private var searchQuery = ""
    @State private var searchResults: [String] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !jailbreakManager.isJailbroken {
                    lockedView
                } else {
                    fileListView
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if jailbreakManager.isJailbroken {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: { showingSearchSheet = true }) {
                            Image(systemName: "magnifyingglass")
                        }
                        
                        Menu {
                            Button(action: { showingNewFileSheet = true }) {
                                Label("New File", systemImage: "doc.badge.plus")
                            }
                            Button(action: { showingNewFolderSheet = true }) {
                                Label("New Folder", systemImage: "folder.badge.plus")
                            }
                            Divider()
                            Button(action: { fileManager.refresh() }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewFileSheet) {
                newItemSheet(isFolder: false)
            }
            .sheet(isPresented: $showingNewFolderSheet) {
                newItemSheet(isFolder: true)
            }
            .sheet(isPresented: $showingSearchSheet) {
                searchSheet
            }
            .sheet(isPresented: $showingFileEditor) {
                if let file = selectedFile {
                    FileEditorView(filePath: file.path, fileManager: fileManager)
                }
            }
            .sheet(isPresented: $showingRenameSheet) {
                renameSheet
            }
            .sheet(isPresented: $showingPermissionsSheet) {
                if let file = selectedFile {
                    permissionsSheet(file: file)
                }
            }
            .confirmationDialog("File Actions", isPresented: $showingActionSheet, titleVisibility: .visible) {
                if let file = selectedFile {
                    if !file.isDirectory {
                        Button("Edit") {
                            showingFileEditor = true
                        }
                    }
                    Button("Rename") {
                        newItemName = file.name
                        showingRenameSheet = true
                    }
                    Button("Copy Path") {
                        UIPasteboard.general.string = file.path
                    }
                    Button("Permissions") {
                        showingPermissionsSheet = true
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            }
            .confirmationDialog("Delete \(selectedFile?.name ?? "")?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let file = selectedFile {
                        deleteItem(file)
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Locked View
    
    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("File Manager Locked")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete jailbreak to access file system with root privileges")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - File List View
    
    private var fileListView: some View {
        VStack(spacing: 0) {
            // Path bar
            pathBar
            
            // File list
            if fileManager.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if fileManager.items.isEmpty {
                emptyDirectoryView
            } else {
                List {
                    ForEach(fileManager.items) { item in
                        FileRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleItemTap(item)
                            }
                            .onLongPressGesture {
                                selectedFile = item
                                showingActionSheet = true
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Path Bar
    
    private var pathBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                Button(action: { fileManager.navigateTo("/") }) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                }
                
                let components = fileManager.currentPath.split(separator: "/")
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        let path = "/" + components.prefix(index + 1).joined(separator: "/")
                        fileManager.navigateTo(path)
                    }) {
                        Text(String(component))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Empty Directory View
    
    private var emptyDirectoryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Empty Directory")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - New Item Sheet
    
    private func newItemSheet(isFolder: Bool) -> some View {
        NavigationView {
            Form {
                Section(header: Text(isFolder ? "Folder Name" : "File Name")) {
                    TextField("Name", text: $newItemName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Location")) {
                    Text(fileManager.currentPath)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(isFolder ? "New Folder" : "New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newItemName = ""
                        showingNewFileSheet = false
                        showingNewFolderSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createItem(isFolder: isFolder)
                    }
                    .disabled(newItemName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Search Sheet
    
    private var searchSheet: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search files...", text: $searchQuery)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                if searchResults.isEmpty {
                    Spacer()
                    Text("Enter a search term")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(searchResults, id: \.self) { path in
                        VStack(alignment: .leading) {
                            Text((path as NSString).lastPathComponent)
                                .font(.headline)
                            Text(path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            let parentPath = (path as NSString).deletingLastPathComponent
                            fileManager.navigateTo(parentPath)
                            showingSearchSheet = false
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingSearchSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Rename Sheet
    
    private var renameSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("New Name")) {
                    TextField("Name", text: $newItemName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingRenameSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Rename") {
                        renameItem()
                    }
                    .disabled(newItemName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Permissions Sheet
    
    private func permissionsSheet(file: FileItem) -> some View {
        NavigationView {
            Form {
                Section(header: Text("Current Permissions")) {
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text(file.permissions)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Owner")
                        Spacer()
                        Text(file.owner)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Group")
                        Spacer()
                        Text(file.group)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Quick Actions")) {
                    Button("Make Executable (755)") {
                        _ = ExploitBridge.chmod(file.path, permissions: "755")
                        fileManager.refresh()
                        showingPermissionsSheet = false
                    }
                    
                    Button("Read Only (444)") {
                        _ = ExploitBridge.chmod(file.path, permissions: "444")
                        fileManager.refresh()
                        showingPermissionsSheet = false
                    }
                    
                    Button("Full Access (777)") {
                        _ = ExploitBridge.chmod(file.path, permissions: "777")
                        fileManager.refresh()
                        showingPermissionsSheet = false
                    }
                }
            }
            .navigationTitle("Permissions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showingPermissionsSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleItemTap(_ item: FileItem) {
        if item.isDirectory {
            fileManager.navigateTo(item.path)
        } else {
            selectedFile = item
            showingFileEditor = true
        }
    }
    
    private func createItem(isFolder: Bool) {
        let path = (fileManager.currentPath as NSString).appendingPathComponent(newItemName)
        
        var success: Bool
        if isFolder {
            success = ExploitBridge.createDirectory(path)
        } else {
            success = ExploitBridge.writeFile(path, contents: "")
        }
        
        if success {
            fileManager.refresh()
        } else {
            errorMessage = "Failed to create \(isFolder ? "folder" : "file")"
            showingError = true
        }
        
        newItemName = ""
        showingNewFileSheet = false
        showingNewFolderSheet = false
    }
    
    private func deleteItem(_ item: FileItem) {
        if ExploitBridge.deleteItem(item.path) {
            fileManager.refresh()
        } else {
            errorMessage = "Failed to delete \(item.name)"
            showingError = true
        }
    }
    
    private func renameItem() {
        guard let file = selectedFile else { return }
        
        let newPath = ((file.path as NSString).deletingLastPathComponent as NSString).appendingPathComponent(newItemName)
        
        if ExploitBridge.moveItem(from: file.path, to: newPath) {
            fileManager.refresh()
        } else {
            errorMessage = "Failed to rename \(file.name)"
            showingError = true
        }
        
        newItemName = ""
        showingRenameSheet = false
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        if let results = ExploitBridge.searchFiles(in: fileManager.currentPath, pattern: searchQuery) {
            searchResults = results
        } else {
            searchResults = []
        }
    }
}

// MARK: - File Row View

struct FileRowView: View {
    let item: FileItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(item.permissions)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(item.formattedSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(item.owner):\(item.group)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron for directories
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconColor: Color {
        if item.isDirectory {
            return .blue
        } else if item.isSymlink {
            return .purple
        } else if item.isExecutable {
            return .green
        } else {
            return .gray
        }
    }
}

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
                if !jailbreakManager.isComplete {
                    lockedView
                } else {
                    fileListView
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if jailbreakManager.isComplete {
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
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("File Actions"),
                    buttons: fileActionButtons()
                )
            }
            .actionSheet(isPresented: $showingDeleteConfirm) {
                ActionSheet(
                    title: Text("Delete \(selectedFile?.name ?? "")?"),
                    message: Text("This action cannot be undone."),
                    buttons: [
                        .destructive(Text("Delete")) {
                            if let file = selectedFile {
                                deleteItem(file)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func fileActionButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        if let file = selectedFile {
            if !file.isDirectory {
                buttons.append(.default(Text("Edit")) {
                    showingFileEditor = true
                })
            }
            buttons.append(.default(Text("Rename")) {
                newItemName = file.name
                showingRenameSheet = true
            })
            buttons.append(.default(Text("Copy Path")) {
                UIPasteboard.general.string = file.path
            })
            buttons.append(.default(Text("Permissions")) {
                showingPermissionsSheet = true
            })
            buttons.append(.destructive(Text("Delete")) {
                showingDeleteConfirm = true
            })
        }
        
        buttons.append(.cancel())
        return buttons
    }
    
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
    
    private var fileListView: some View {
        VStack(spacing: 0) {
            pathBar
            
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
                
                if searchResults.isEmpty && !searchQuery.isEmpty {
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults, id: \.self) { result in
                        Button(action: {
                            let parentPath = (result as NSString).deletingLastPathComponent
                            fileManager.navigateTo(parentPath)
                            showingSearchSheet = false
                        }) {
                            VStack(alignment: .leading) {
                                Text((result as NSString).lastPathComponent)
                                    .font(.headline)
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
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
                        newItemName = ""
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
    
    private func permissionsSheet(file: FileItem) -> some View {
        NavigationView {
            Form {
                Section(header: Text("File Info")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(file.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Path")
                        Spacer()
                        Text(file.path)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    HStack {
                        Text("Size")
                        Spacer()
                        Text(file.formattedSize)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Permissions")
                        Spacer()
                        Text(file.permissions)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Section(header: Text("Quick Actions")) {
                    Button("Make Executable (755)") {
                        setPermissions(file: file, mode: "755")
                    }
                    Button("Read Only (444)") {
                        setPermissions(file: file, mode: "444")
                    }
                    Button("Full Access (777)") {
                        setPermissions(file: file, mode: "777")
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
        
        var success = false
        if isFolder {
            success = fileManager.createDirectory(at: path)
        } else {
            success = fileManager.createFile(at: path, content: "")
        }
        
        if success {
            newItemName = ""
            showingNewFileSheet = false
            showingNewFolderSheet = false
            fileManager.refresh()
        } else {
            errorMessage = "Failed to create \(isFolder ? "folder" : "file")"
            showingError = true
        }
    }
    
    private func deleteItem(_ item: FileItem) {
        if fileManager.deleteItem(at: item.path) {
            fileManager.refresh()
        } else {
            errorMessage = "Failed to delete \(item.name)"
            showingError = true
        }
    }
    
    private func renameItem() {
        guard let file = selectedFile else { return }
        
        let parentPath = (file.path as NSString).deletingLastPathComponent
        let newPath = (parentPath as NSString).appendingPathComponent(newItemName)
        
        if fileManager.moveItem(from: file.path, to: newPath) {
            newItemName = ""
            showingRenameSheet = false
            fileManager.refresh()
        } else {
            errorMessage = "Failed to rename \(file.name)"
            showingError = true
        }
    }
    
    private func setPermissions(file: FileItem, mode: String) {
        if fileManager.setPermissions(at: file.path, mode: mode) {
            showingPermissionsSheet = false
            fileManager.refresh()
        } else {
            errorMessage = "Failed to set permissions"
            showingError = true
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        searchResults = fileManager.search(query: searchQuery, in: fileManager.currentPath)
    }
}

struct FileRowView: View {
    let item: FileItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(item.iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(item.permissions)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !item.isDirectory {
                        Text(item.formattedSize)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

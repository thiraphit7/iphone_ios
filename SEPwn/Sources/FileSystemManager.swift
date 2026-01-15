/*
 * FileSystemManager.swift - File System Manager
 * iOS 26.1 Jailbreak for iPhone Air
 * 
 * All file operations use real exploit via ExploitBridge
 * No simulation - requires jailbroken device with root access
 */

import Foundation
import SwiftUI

@MainActor
class FileSystemManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPath: String = "/"
    @Published var items: [FileItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var navigationHistory: [String] = ["/"]
    @Published var historyIndex: Int = 0
    
    // MARK: - Bookmarks
    static let defaultBookmarks: [(name: String, path: String, icon: String)] = [
        ("Root", "/", "house.fill"),
        ("Applications", "/Applications", "app.fill"),
        ("System Apps", "/var/containers/Bundle/Application", "apps.iphone"),
        ("User Data", "/var/mobile", "person.fill"),
        ("Documents", "/var/mobile/Documents", "doc.fill"),
        ("Preferences", "/var/mobile/Library/Preferences", "gear"),
        ("Jailbreak", "/var/jb", "terminal.fill"),
        ("Tweaks", "/var/jb/Library/MobileSubstrate/DynamicLibraries", "puzzlepiece.fill"),
        ("Logs", "/var/log", "doc.text.fill"),
        ("Tmp", "/tmp", "clock.fill")
    ]
    
    // MARK: - Initialization
    init() {
        loadDirectory("/")
    }
    
    // MARK: - Navigation
    
    /// Navigate to a specific path
    func navigateTo(_ path: String) {
        guard ExploitBridge.isExploitActive() else {
            errorMessage = "Exploit not active"
            return
        }
        
        // Normalize path
        var normalizedPath = path
        if normalizedPath.isEmpty {
            normalizedPath = "/"
        }
        
        // Remove trailing slash except for root
        if normalizedPath.count > 1 && normalizedPath.hasSuffix("/") {
            normalizedPath = String(normalizedPath.dropLast())
        }
        
        // Check if path exists and is a directory
        guard ExploitBridge.isDirectory(normalizedPath) else {
            errorMessage = "Path does not exist or is not a directory"
            return
        }
        
        // Update history
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory = Array(navigationHistory.prefix(historyIndex + 1))
        }
        navigationHistory.append(normalizedPath)
        historyIndex = navigationHistory.count - 1
        
        loadDirectory(normalizedPath)
    }
    
    /// Go back in navigation history
    func goBack() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        loadDirectory(navigationHistory[historyIndex])
    }
    
    /// Go forward in navigation history
    func goForward() {
        guard historyIndex < navigationHistory.count - 1 else { return }
        historyIndex += 1
        loadDirectory(navigationHistory[historyIndex])
    }
    
    /// Go to parent directory
    func goUp() {
        guard currentPath != "/" else { return }
        let parentPath = (currentPath as NSString).deletingLastPathComponent
        navigateTo(parentPath)
    }
    
    /// Refresh current directory
    func refresh() {
        loadDirectory(currentPath)
    }
    
    // MARK: - Directory Loading
    
    private func loadDirectory(_ path: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            if let loadedItems = ExploitBridge.listDirectory(path) {
                await MainActor.run {
                    self.currentPath = path
                    self.items = loadedItems
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Failed to load directory"
                    self.items = []
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - File Operations
    
    /// Create a new file
    func createFile(name: String, contents: String = "") -> Bool {
        let path = (currentPath as NSString).appendingPathComponent(name)
        let success = ExploitBridge.writeFile(path, contents: contents)
        if success {
            refresh()
        }
        return success
    }
    
    /// Create a new file at specific path
    func createFile(at path: String, content: String) -> Bool {
        let success = ExploitBridge.writeFile(path, contents: content)
        if success {
            refresh()
        }
        return success
    }
    
    /// Create a new directory
    func createDirectory(name: String) -> Bool {
        let path = (currentPath as NSString).appendingPathComponent(name)
        let success = ExploitBridge.createDirectory(path)
        if success {
            refresh()
        }
        return success
    }
    
    /// Create a new directory at specific path
    func createDirectory(at path: String) -> Bool {
        let success = ExploitBridge.createDirectory(path)
        if success {
            refresh()
        }
        return success
    }
    
    /// Delete a file or directory
    func deleteItem(at path: String) -> Bool {
        let success = ExploitBridge.deleteItem(path)
        if success {
            refresh()
        }
        return success
    }
    
    /// Rename a file or directory
    func renameItem(from oldPath: String, to newName: String) -> Bool {
        let parentPath = (oldPath as NSString).deletingLastPathComponent
        let newPath = (parentPath as NSString).appendingPathComponent(newName)
        let success = ExploitBridge.moveItem(from: oldPath, to: newPath)
        if success {
            refresh()
        }
        return success
    }
    
    /// Move a file or directory
    func moveItem(from sourcePath: String, to destinationPath: String) -> Bool {
        let success = ExploitBridge.moveItem(from: sourcePath, to: destinationPath)
        if success {
            refresh()
        }
        return success
    }
    
    /// Copy a file or directory
    func copyItem(from sourcePath: String, to destinationPath: String) -> Bool {
        let success = ExploitBridge.copyItem(from: sourcePath, to: destinationPath)
        if success {
            refresh()
        }
        return success
    }
    
    /// Read file contents
    func readFile(at path: String) -> String? {
        return ExploitBridge.readFile(path)
    }
    
    /// Write file contents
    func writeFile(at path: String, contents: String) -> Bool {
        return ExploitBridge.writeFile(path, contents: contents)
    }
    
    /// Change file permissions
    func chmod(path: String, permissions: String) -> Bool {
        let success = ExploitBridge.chmod(path, permissions: permissions)
        if success {
            refresh()
        }
        return success
    }
    
    /// Change file owner
    func chown(path: String, owner: String, group: String? = nil) -> Bool {
        let success = ExploitBridge.chown(path, owner: owner, group: group)
        if success {
            refresh()
        }
        return success
    }
    
    /// Search for files
    func searchFiles(pattern: String) -> [String] {
        return ExploitBridge.searchFiles(in: currentPath, pattern: pattern) ?? []
    }
    
    /// Set permissions at path
    func setPermissions(at path: String, mode: String) -> Bool {
        let success = ExploitBridge.chmod(path, permissions: mode)
        if success {
            refresh()
        }
        return success
    }
    
    /// Search for files with query in path
    func search(query: String, in path: String) -> [String] {
        return ExploitBridge.searchFiles(in: path, pattern: query) ?? []
    }
    
    /// Get file info
    func getFileInfo(at path: String) -> FileInfo? {
        return ExploitBridge.getFileInfo(path)
    }
    
    // MARK: - Helpers
    
    /// Check if can go back
    var canGoBack: Bool {
        return historyIndex > 0
    }
    
    /// Check if can go forward
    var canGoForward: Bool {
        return historyIndex < navigationHistory.count - 1
    }
    
    /// Check if at root
    var isAtRoot: Bool {
        return currentPath == "/"
    }
    
    /// Get path components for breadcrumb
    var pathComponents: [String] {
        if currentPath == "/" {
            return ["/"]
        }
        var components = currentPath.split(separator: "/").map { String($0) }
        components.insert("/", at: 0)
        return components
    }
    
    /// Get path for component index
    func pathForComponent(at index: Int) -> String {
        if index == 0 {
            return "/"
        }
        let components = currentPath.split(separator: "/")
        let subComponents = components.prefix(index)
        return "/" + subComponents.joined(separator: "/")
    }
}

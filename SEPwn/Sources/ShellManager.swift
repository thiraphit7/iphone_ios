/*
 * ShellManager.swift - Interactive Shell Process Manager
 * iOS 26.1 Jailbreak for iPhone Air
 * 
 * All commands executed via real exploit using posix_spawn
 * No simulation - requires jailbroken device with root access
 */

import Foundation
import SwiftUI

@MainActor
class ShellManager: ObservableObject {
    // MARK: - Published Properties
    @Published var outputLines: [TerminalLine] = []
    @Published var isConnected: Bool = false
    @Published var currentDirectory: String = "/var/root"
    
    // MARK: - Private Properties
    private var commandHistory: [String] = []
    private var historyIndex: Int = 0
    
    // MARK: - Initialization
    init() {
        addSystemLine("SEPwn Terminal v1.0")
        addSystemLine("Real exploit shell - All commands executed with root privileges")
        addSystemLine("Type 'help' for available commands")
        addSystemLine("")
    }
    
    // MARK: - Public Methods
    
    /// Start the shell session
    func startShell() {
        guard ExploitBridge.isExploitActive() else {
            addErrorLine("Error: Exploit not active. Run jailbreak first.")
            return
        }
        
        isConnected = true
        addSystemLine("Shell session started with root privileges")
        addSystemLine("uid=0(root) gid=0(wheel)")
        addSystemLine("")
        
        // Get actual current directory
        if let pwd = ExploitBridge.executeShellCommand("pwd") {
            currentDirectory = pwd.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    /// Stop the shell session
    func stopShell() {
        isConnected = false
        addSystemLine("Shell session ended")
    }
    
    /// Execute a command using real exploit
    func executeCommand(_ command: String) {
        guard ExploitBridge.isExploitActive() else {
            addErrorLine("Error: Exploit not active")
            return
        }
        
        // Add command to history
        commandHistory.append(command)
        historyIndex = commandHistory.count
        
        // Display the command
        outputLines.append(TerminalLine(text: command, isCommand: true, type: .command))
        
        // Process the command
        processCommand(command)
    }
    
    /// Clear terminal output
    func clearOutput() {
        outputLines.removeAll()
        addSystemLine("Terminal cleared")
    }
    
    /// Get previous command from history
    func getPreviousCommand() -> String? {
        guard historyIndex > 0 else { return nil }
        historyIndex -= 1
        return commandHistory[historyIndex]
    }
    
    /// Get next command from history
    func getNextCommand() -> String? {
        guard historyIndex < commandHistory.count - 1 else { return nil }
        historyIndex += 1
        return commandHistory[historyIndex]
    }
    
    // MARK: - Private Methods
    
    private func processCommand(_ command: String) {
        let trimmedCommand = command.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedCommand.isEmpty else {
            addOutputLine("")
            return
        }
        
        // Handle built-in commands that don't need shell execution
        if handleBuiltinCommand(trimmedCommand) {
            return
        }
        
        // Execute real system command via exploit
        executeRealCommand(trimmedCommand)
    }
    
    private func handleBuiltinCommand(_ command: String) -> Bool {
        let parts = command.split(separator: " ", maxSplits: 1)
        let cmd = String(parts.first ?? "")
        let args = parts.count > 1 ? String(parts[1]) : ""
        
        switch cmd.lowercased() {
        case "help":
            showHelp()
            return true
            
        case "clear", "cls":
            clearOutput()
            return true
            
        case "history":
            showHistory()
            return true
            
        case "exit", "quit":
            addOutputLine("Use the app's close button to exit")
            return true
            
        case "cd":
            changeDirectory(args)
            return true
            
        default:
            return false
        }
    }
    
    private func executeRealCommand(_ command: String) {
        Task {
            // Build full command with current directory context
            let fullCommand: String
            if currentDirectory != "/" && currentDirectory != "/var/root" {
                fullCommand = "cd '\(currentDirectory)' && \(command)"
            } else {
                fullCommand = command
            }
            
            // Execute via real exploit
            if let output = ExploitBridge.executeShellCommand(fullCommand) {
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    if !line.isEmpty || lines.count == 1 {
                        addOutputLine(line)
                    }
                }
            } else {
                addErrorLine("Command execution failed")
            }
            
            // Update current directory if cd was part of command
            if command.hasPrefix("cd ") {
                if let pwd = ExploitBridge.executeShellCommand("pwd") {
                    currentDirectory = pwd.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            addOutputLine("")
        }
    }
    
    private func showHelp() {
        let helpText = """
        SEPwn Terminal - Real Exploit Shell
        All commands executed with root privileges via posix_spawn
        
        Built-in:
          help      - Show this help message
          clear     - Clear terminal screen
          history   - Show command history
          cd <dir>  - Change directory
          exit      - Exit terminal (use app close)
        
        All other commands are executed directly on the system.
        Examples:
          ls -la /var/root
          cat /etc/passwd
          ps aux
          killall SpringBoard
          apt update
          dpkg -l
        """
        
        for line in helpText.components(separatedBy: "\n") {
            addOutputLine(line)
        }
    }
    
    private func showHistory() {
        if commandHistory.isEmpty {
            addOutputLine("No commands in history")
            return
        }
        
        for (index, cmd) in commandHistory.enumerated() {
            addOutputLine("  \(index + 1)  \(cmd)")
        }
    }
    
    private func changeDirectory(_ path: String) {
        let targetPath: String
        
        if path.isEmpty || path == "~" {
            targetPath = "/var/root"
        } else if path.hasPrefix("/") {
            targetPath = path
        } else if path == ".." {
            let components = currentDirectory.split(separator: "/")
            if components.count > 1 {
                targetPath = "/" + components.dropLast().joined(separator: "/")
            } else {
                targetPath = "/"
            }
        } else {
            targetPath = currentDirectory + "/" + path
        }
        
        // Verify directory exists using real exploit
        if let result = ExploitBridge.executeShellCommand("test -d '\(targetPath)' && echo 'exists'") {
            if result.contains("exists") {
                currentDirectory = targetPath
                addOutputLine("")
            } else {
                addErrorLine("-bash: cd: \(path): No such file or directory")
            }
        } else {
            addErrorLine("-bash: cd: \(path): Permission denied or not found")
        }
    }
    
    // MARK: - Output Helpers
    
    private func addOutputLine(_ text: String) {
        outputLines.append(TerminalLine(text: text, type: .output))
    }
    
    private func addErrorLine(_ text: String) {
        outputLines.append(TerminalLine(text: text, type: .error))
    }
    
    private func addSystemLine(_ text: String) {
        outputLines.append(TerminalLine(text: text, type: .system))
    }
}

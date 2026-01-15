/*
 * TerminalView.swift - Interactive Shell Terminal UI
 * iOS 26.1 Jailbreak for iPhone Air
 */

import SwiftUI

struct TerminalView: View {
    @StateObject private var shellManager = ShellManager()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal Header
            terminalHeader
            
            // Terminal Output
            terminalOutput
            
            // Input Field
            terminalInput
        }
        .background(Color.black)
        .onAppear {
            shellManager.startShell()
        }
        .onDisappear {
            shellManager.stopShell()
        }
    }
    
    // MARK: - Terminal Header
    private var terminalHeader: some View {
        HStack {
            // Terminal title
            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.green)
                Text("root@iPhone:~#")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(shellManager.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(shellManager.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Clear button
            Button(action: {
                shellManager.clearOutput()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    // MARK: - Terminal Output
    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(shellManager.outputLines) { line in
                        TerminalLineView(line: line)
                            .id(line.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .onChange(of: shellManager.outputLines.count) { _ in
                if let lastLine = shellManager.outputLines.last {
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Terminal Input
    private var terminalInput: some View {
        HStack(spacing: 8) {
            // Prompt
            Text("$")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)
            
            // Input field
            TextField("Enter command...", text: $inputText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isInputFocused)
                .onSubmit {
                    executeCommand()
                }
            
            // Send button
            Button(action: {
                executeCommand()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? .gray : .green)
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    // MARK: - Helper Methods
    private func executeCommand() {
        guard !inputText.isEmpty else { return }
        
        let command = inputText
        inputText = ""
        
        shellManager.executeCommand(command)
    }
}

// MARK: - Terminal Line View
struct TerminalLineView: View {
    let line: TerminalLine
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if line.isCommand {
                Text("$ ")
                    .foregroundColor(.green)
            }
            
            Text(line.text)
                .foregroundColor(line.color)
        }
        .font(.system(.caption, design: .monospaced))
        .textSelection(.enabled)
    }
}

// MARK: - Terminal Line Model
struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    let isCommand: Bool
    let type: LineType
    
    enum LineType {
        case command
        case output
        case error
        case system
    }
    
    var color: Color {
        switch type {
        case .command: return .white
        case .output: return .white
        case .error: return .red
        case .system: return .yellow
        }
    }
    
    init(text: String, isCommand: Bool = false, type: LineType = .output) {
        self.text = text
        self.isCommand = isCommand
        self.type = type
    }
}

// MARK: - Quick Commands View
struct QuickCommandsView: View {
    let onCommand: (String) -> Void
    
    private let commands = [
        ("whoami", "Check user"),
        ("id", "User ID"),
        ("uname -a", "System info"),
        ("ls -la", "List files"),
        ("pwd", "Current dir"),
        ("ps aux", "Processes"),
        ("df -h", "Disk usage"),
        ("cat /etc/passwd", "Users")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(commands, id: \.0) { cmd, label in
                    Button(action: {
                        onCommand(cmd)
                    }) {
                        Text(cmd)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview
struct TerminalView_Previews: PreviewProvider {
    static var previews: some View {
        TerminalView()
            .preferredColorScheme(.dark)
    }
}

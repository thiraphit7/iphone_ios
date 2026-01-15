/*
 * ContentView.swift - Main SwiftUI View with TabView
 * iOS 26.1 Jailbreak for iPhone Air
 */

import SwiftUI

struct ContentView: View {
    @StateObject private var jailbreakManager = JailbreakManager()
    @State private var selectedTab: Tab = .jailbreak
    
    enum Tab {
        case jailbreak
        case terminal
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Jailbreak Tab
            JailbreakView(jailbreakManager: jailbreakManager)
                .tabItem {
                    Label("Jailbreak", systemImage: "lock.open.fill")
                }
                .tag(Tab.jailbreak)
            
            // Terminal Tab (only enabled after jailbreak)
            Group {
                if jailbreakManager.isComplete {
                    TerminalView()
                } else {
                    TerminalLockedView()
                }
            }
            .tabItem {
                Label("Terminal", systemImage: "terminal.fill")
            }
            .tag(Tab.terminal)
            
            // Settings Tab
            SettingsView(jailbreakManager: jailbreakManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .preferredColorScheme(.dark)
        .accentColor(.green)
    }
}

// MARK: - Jailbreak View
struct JailbreakView: View {
    @ObservedObject var jailbreakManager: JailbreakManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Status Section
                statusSection
                
                // Progress
                progressSection
                
                // Jailbreak Button
                jailbreakButton
                
                // Log View
                logSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("SEPwn")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("iOS 26.1 Jailbreak")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("iPhone Air (iPhone18,4)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(jailbreakManager.statusColor)
                    .frame(width: 12, height: 12)
                
                Text(jailbreakManager.currentStage)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            if !jailbreakManager.statusMessage.isEmpty {
                Text(jailbreakManager.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: jailbreakManager.progress)
                .progressViewStyle(.linear)
                .tint(jailbreakManager.statusColor)
            
            Text("\(Int(jailbreakManager.progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Jailbreak Button
    private var jailbreakButton: some View {
        Button(action: {
            Task {
                await jailbreakManager.startJailbreak()
            }
        }) {
            HStack {
                if jailbreakManager.isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(jailbreakManager.buttonTitle)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(jailbreakManager.isRunning ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(jailbreakManager.isRunning)
    }
    
    // MARK: - Log Section
    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Log")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    jailbreakManager.clearLogs()
                }
                .font(.caption)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(jailbreakManager.logs) { log in
                            LogEntryView(entry: log)
                                .id(log.id)
                        }
                    }
                }
                .onChange(of: jailbreakManager.logs.count) { newCount in
                    if let lastLog = jailbreakManager.logs.last {
                        withAnimation {
                            proxy.scrollTo(lastLog.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .font(.system(.caption, design: .monospaced))
        }
    }
}

// MARK: - Terminal Locked View
struct TerminalLockedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Terminal Locked")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete the jailbreak process to unlock the terminal")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            HStack {
                Image(systemName: "arrow.left")
                Text("Go to Jailbreak tab")
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var jailbreakManager: JailbreakManager
    @State private var showPasswordSheet = false
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            List {
                // Device Info Section
                Section(header: Text("Device Information")) {
                    InfoRow(label: "Device", value: "iPhone Air")
                    InfoRow(label: "Model", value: "iPhone18,4")
                    InfoRow(label: "iOS Version", value: "26.1")
                    InfoRow(label: "Build", value: "23B85")
                    InfoRow(label: "Kernel", value: "Darwin 25.1.0")
                }
                
                // Jailbreak Status Section
                Section(header: Text("Jailbreak Status")) {
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(jailbreakManager.isComplete ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(jailbreakManager.isComplete ? "Jailbroken" : "Not Jailbroken")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if jailbreakManager.isComplete {
                        InfoRow(label: "Root Password", value: "alpine (default)")
                    }
                }
                
                // Actions Section (only if jailbroken)
                if jailbreakManager.isComplete {
                    Section(header: Text("Actions")) {
                        Button(action: {
                            showPasswordSheet = true
                        }) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.orange)
                                Text("Change Root Password")
                            }
                        }
                        
                        Button(action: {
                            ExploitBridge.respring()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                Text("Respring")
                            }
                        }
                        
                        Button(action: {
                            // Open Sileo
                        }) {
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.purple)
                                Text("Open Sileo")
                            }
                        }
                        
                        Button(action: {
                            // Open Zebra
                        }) {
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.cyan)
                                Text("Open Zebra")
                            }
                        }
                    }
                    
                    // SSH Section
                    Section(header: Text("SSH Access")) {
                        InfoRow(label: "SSH Status", value: "Running")
                        InfoRow(label: "Port", value: "22")
                        InfoRow(label: "User", value: "root")
                        
                        Button(action: {
                            UIPasteboard.general.string = "ssh root@<device-ip>"
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                                Text("Copy SSH Command")
                            }
                        }
                    }
                }
                
                // About Section
                Section(header: Text("About")) {
                    InfoRow(label: "SEPwn Version", value: "1.0.0")
                    InfoRow(label: "Build Date", value: "January 2026")
                    
                    Link(destination: URL(string: "https://github.com/thiraphit7/iphone_ios")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPasswordSheet) {
                PasswordChangeSheet(
                    newPassword: $newPassword,
                    confirmPassword: $confirmPassword,
                    onSave: {
                        Task {
                            await jailbreakManager.setRootPassword(newPassword)
                        }
                        showPasswordSheet = false
                        newPassword = ""
                        confirmPassword = ""
                    },
                    onCancel: {
                        showPasswordSheet = false
                        newPassword = ""
                        confirmPassword = ""
                    }
                )
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Password Change Sheet
struct PasswordChangeSheet: View {
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Password")) {
                    SecureField("Enter new password", text: $newPassword)
                    SecureField("Confirm password", text: $confirmPassword)
                }
                
                if !newPassword.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                    Section {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                    }
                }
                
                Section(footer: Text("This will change the root password for SSH and sudo access.")) {
                    Button("Save Password") {
                        onSave()
                    }
                    .disabled(!passwordsMatch)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Log Entry View
struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.timestamp)
                .foregroundColor(.secondary)
            
            Text(entry.levelIcon)
            
            Text(entry.message)
                .foregroundColor(entry.levelColor)
        }
    }
}

// MARK: - Log Entry Model
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: String
    let level: LogLevel
    let message: String
    
    enum LogLevel {
        case info, success, warning, error
    }
    
    var levelIcon: String {
        switch level {
        case .info: return "ℹ️"
        case .success: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var levelColor: Color {
        switch level {
        case .info: return .primary
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

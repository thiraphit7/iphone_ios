/*
 * ContentView.swift - Main SwiftUI View
 * iOS 26.1 Jailbreak for iPhone Air
 */

import SwiftUI

struct ContentView: View {
    @StateObject private var jailbreakManager = JailbreakManager()
    
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
        .preferredColorScheme(.dark)
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

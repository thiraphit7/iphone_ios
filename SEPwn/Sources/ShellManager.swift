/*
 * ShellManager.swift - Interactive Shell Process Manager
 * iOS 26.1 Jailbreak for iPhone Air
 */

import Foundation
import SwiftUI

@MainActor
class ShellManager: ObservableObject {
    // MARK: - Published Properties
    @Published var outputLines: [TerminalLine] = []
    @Published var isConnected: Bool = false
    @Published var currentDirectory: String = "~"
    
    // MARK: - Private Properties
    private var shellProcess: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var commandHistory: [String] = []
    private var historyIndex: Int = 0
    
    // MARK: - Initialization
    init() {
        addSystemLine("SEPwn Terminal v1.0")
        addSystemLine("Type 'help' for available commands")
        addSystemLine("")
    }
    
    // MARK: - Public Methods
    
    /// Start the shell session
    func startShell() {
        isConnected = true
        addSystemLine("Shell session started")
        addSystemLine("Welcome to SEPwn Terminal")
        addSystemLine("")
        
        // In real implementation, this would spawn a shell process
        // For now, we simulate shell behavior
        
        #if targetEnvironment(simulator)
        addSystemLine("[Simulator Mode - Commands are simulated]")
        addSystemLine("")
        #endif
    }
    
    /// Stop the shell session
    func stopShell() {
        isConnected = false
        shellProcess?.terminate()
        shellProcess = nil
        addSystemLine("Shell session ended")
    }
    
    /// Execute a command
    func executeCommand(_ command: String) {
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
        
        // Handle built-in commands
        if handleBuiltinCommand(trimmedCommand) {
            return
        }
        
        // Execute system command
        executeSystemCommand(trimmedCommand)
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
            
        case "export":
            handleExport(args)
            return true
            
        case "alias":
            addOutputLine("Aliases not supported in this shell")
            return true
            
        default:
            return false
        }
    }
    
    private func executeSystemCommand(_ command: String) {
        // In a real jailbroken environment, this would use posix_spawn or system()
        // For now, we simulate common commands
        
        Task {
            let output = await runCommand(command)
            
            for line in output.components(separatedBy: "\n") {
                if !line.isEmpty {
                    addOutputLine(line)
                }
            }
            
            // Add empty line after output
            addOutputLine("")
        }
    }
    
    private func runCommand(_ command: String) async -> String {
        // Simulate command execution
        // In real implementation, this would use Process or posix_spawn
        
        let parts = command.split(separator: " ")
        let cmd = String(parts.first ?? "")
        let args = Array(parts.dropFirst().map { String($0) })
        
        switch cmd {
        case "whoami":
            return "root"
            
        case "id":
            return "uid=0(root) gid=0(wheel) groups=0(wheel),1(daemon),2(kmem),3(sys),4(tty),5(operator),8(procview),9(procmod),20(staff),29(certusers),80(admin),501(mobile)"
            
        case "uname":
            if args.contains("-a") {
                return "Darwin iPhone 25.1.0 Darwin Kernel Version 25.1.0: Thu Oct 23 11:12:58 PDT 2025; root:xnu-12377.42.6~55/RELEASE_ARM64_T8150 iPhone14,3 arm64 iPhone"
            }
            return "Darwin"
            
        case "hostname":
            return "iPhone"
            
        case "pwd":
            return currentDirectory == "~" ? "/var/root" : currentDirectory
            
        case "ls":
            return simulateLS(args)
            
        case "cat":
            return simulateCat(args)
            
        case "echo":
            return args.joined(separator: " ")
            
        case "date":
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM dd HH:mm:ss zzz yyyy"
            return formatter.string(from: Date())
            
        case "uptime":
            return " 07:17:00 up 2 days, 14:32, 1 user, load averages: 1.23 1.45 1.67"
            
        case "df":
            return simulateDF()
            
        case "ps":
            return simulatePS()
            
        case "env":
            return simulateEnv()
            
        case "which":
            if let arg = args.first {
                return "/var/jb/usr/bin/\(arg)"
            }
            return ""
            
        case "killall":
            if let process = args.first {
                return "Killed: \(process)"
            }
            return "usage: killall [-signal] process_name"
            
        case "respring":
            addSystemLine("Triggering respring...")
            ExploitBridge.respring()
            return "Respring initiated"
            
        case "passwd":
            return "Changing password for root.\nNew password: "
            
        case "apt", "dpkg", "apt-get":
            return "Package manager command: \(command)\nUse Sileo or Zebra for package management"
            
        case "ssh":
            return "usage: ssh [-46AaCfGgKkMNnqsTtVvXxYy] [-B bind_interface]\n           [-b bind_address] [-c cipher_spec] [-D [bind_address:]port]\n           [-E log_file] [-e escape_char] [-F configfile] [-I pkcs11]\n           [-i identity_file] [-J [user@]host[:port]] [-L address]\n           [-l login_name] [-m mac_spec] [-O ctl_cmd] [-o option] [-p port]\n           [-Q query_option] [-R address] [-S ctl_path] [-W host:port]\n           [-w local_tun[:remote_tun]] destination [command]"
            
        case "scp":
            return "usage: scp [-346BCpqrTv] [-c cipher] [-F ssh_config] [-i identity_file]\n           [-J destination] [-l limit] [-o ssh_option] [-P port]\n           [-S program] source ... target"
            
        case "ping":
            if let host = args.first {
                return "PING \(host) (8.8.8.8): 56 data bytes\n64 bytes from 8.8.8.8: icmp_seq=0 ttl=117 time=12.345 ms\n64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=11.234 ms\n--- \(host) ping statistics ---\n2 packets transmitted, 2 packets received, 0.0% packet loss"
            }
            return "usage: ping [-AaDdfnoQqRrv] [-c count] [-G sweepmaxsize]\n            [-g sweepminsize] [-h sweepincrsize] [-i wait]\n            [-l preload] [-M mask | time] [-m ttl] [-p pattern]\n            [-S src_addr] [-s packetsize] [-t timeout][-W waittime]\n            [-z tos] host"
            
        case "ifconfig":
            return simulateIfconfig()
            
        case "netstat":
            return "Active Internet connections\nProto Recv-Q Send-Q  Local Address          Foreign Address        (state)\ntcp4       0      0  192.168.1.100.52341    17.253.144.10.443      ESTABLISHED"
            
        default:
            // Try to execute via ExploitBridge
            if let result = ExploitBridge.runCommand(command) {
                return result
            }
            return "-bash: \(cmd): command not found"
        }
    }
    
    // MARK: - Simulation Helpers
    
    private func simulateLS(_ args: [String]) -> String {
        let showAll = args.contains("-a") || args.contains("-la") || args.contains("-al")
        let longFormat = args.contains("-l") || args.contains("-la") || args.contains("-al")
        
        var files = [
            (".", "drwxr-xr-x", "root", "wheel", "160", "Jan 15 07:17"),
            ("..", "drwxr-xr-x", "root", "wheel", "160", "Jan 15 07:17"),
            (".bash_history", "-rw-------", "root", "wheel", "1024", "Jan 15 07:15"),
            (".bashrc", "-rw-r--r--", "root", "wheel", "256", "Jan 14 12:00"),
            (".profile", "-rw-r--r--", "root", "wheel", "128", "Jan 14 12:00"),
            ("Documents", "drwxr-xr-x", "root", "wheel", "96", "Jan 15 06:00"),
            ("Library", "drwxr-xr-x", "root", "wheel", "128", "Jan 15 07:00"),
        ]
        
        if !showAll {
            files = files.filter { !$0.0.hasPrefix(".") }
        }
        
        if longFormat {
            return "total \(files.count * 8)\n" + files.map { "\($0.1)  1 \($0.2)  \($0.3)  \($0.4) \($0.5) \($0.0)" }.joined(separator: "\n")
        } else {
            return files.map { $0.0 }.joined(separator: "  ")
        }
    }
    
    private func simulateCat(_ args: [String]) -> String {
        guard let file = args.first else {
            return "usage: cat [-benstuv] [file ...]"
        }
        
        switch file {
        case "/etc/passwd":
            return "root:*:0:0:System Administrator:/var/root:/bin/sh\nmobile:*:501:501:Mobile User:/var/mobile:/bin/sh\ndaemon:*:1:1:System Services:/var/root:/usr/bin/false"
            
        case "/etc/hosts":
            return "127.0.0.1\tlocalhost\n255.255.255.255\tbroadcasthost\n::1\tlocalhost"
            
        case "/var/jb/.installed_sepwn":
            return "SEPwn v1.0\nInstalled: \(Date())\niOS 26.1 (23B85)\niPhone Air (iPhone18,4)"
            
        default:
            return "cat: \(file): No such file or directory"
        }
    }
    
    private func simulateDF() -> String {
        return """
        Filesystem     Size   Used  Avail Capacity  Mounted on
        /dev/disk0s1s1 256Gi  128Gi  128Gi    50%    /
        /dev/disk0s1s2 256Gi   64Gi  192Gi    25%    /private/var
        """
    }
    
    private func simulatePS() -> String {
        return """
        USER       PID  %CPU %MEM      VSZ    RSS   TT  STAT STARTED      TIME COMMAND
        root         1   0.0  0.1  4268032   8192   ??  Ss   Mon12PM   0:12.34 /sbin/launchd
        root        42   0.0  0.2  4301824  16384   ??  Ss   Mon12PM   0:45.67 /usr/libexec/kernelmanagerd
        mobile     123   1.2  5.4  5234688 442368   ??  Ss   07:15AM   2:34.56 /System/Library/CoreServices/SpringBoard.app/SpringBoard
        root       456   0.0  0.1  4268544   8704   ??  Ss   07:16AM   0:01.23 /var/jb/usr/sbin/sshd
        root       789   0.1  0.3  4334592  24576   ??  S    07:17AM   0:00.12 SEPwn
        """
    }
    
    private func simulateEnv() -> String {
        return """
        PATH=/var/jb/usr/local/bin:/var/jb/usr/bin:/var/jb/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
        HOME=/var/root
        USER=root
        SHELL=/bin/sh
        TERM=xterm-256color
        LANG=en_US.UTF-8
        JAILBREAK=SEPwn
        IOS_VERSION=26.1
        """
    }
    
    private func simulateIfconfig() -> String {
        return """
        lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
            inet 127.0.0.1 netmask 0xff000000
            inet6 ::1 prefixlen 128
        en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
            ether aa:bb:cc:dd:ee:ff
            inet 192.168.1.100 netmask 0xffffff00 broadcast 192.168.1.255
            inet6 fe80::1234:5678:abcd:ef00%en0 prefixlen 64 scopeid 0x4
        """
    }
    
    private func showHelp() {
        let helpText = """
        SEPwn Terminal - Available Commands:
        
        Built-in:
          help      - Show this help message
          clear     - Clear terminal screen
          history   - Show command history
          cd <dir>  - Change directory
          exit      - Exit terminal (use app close)
        
        System:
          whoami    - Show current user
          id        - Show user/group IDs
          uname -a  - Show system information
          pwd       - Print working directory
          ls [-la]  - List directory contents
          cat <file>- Display file contents
          ps        - Show running processes
          df -h     - Show disk usage
          ifconfig  - Show network interfaces
          ping      - Test network connectivity
        
        Jailbreak:
          respring  - Restart SpringBoard
          killall   - Kill process by name
          apt/dpkg  - Package management (use Sileo/Zebra)
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
        if path.isEmpty || path == "~" {
            currentDirectory = "~"
            addOutputLine("")
        } else if path == ".." {
            // Go up one directory
            if currentDirectory != "/" && currentDirectory != "~" {
                let components = currentDirectory.split(separator: "/")
                if components.count > 1 {
                    currentDirectory = "/" + components.dropLast().joined(separator: "/")
                } else {
                    currentDirectory = "/"
                }
            }
            addOutputLine("")
        } else if path.hasPrefix("/") {
            currentDirectory = path
            addOutputLine("")
        } else {
            currentDirectory = currentDirectory == "~" ? "/var/root/\(path)" : "\(currentDirectory)/\(path)"
            addOutputLine("")
        }
    }
    
    private func handleExport(_ args: String) {
        if args.isEmpty {
            // Show all exports
            addOutputLine("PATH=/var/jb/usr/local/bin:/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin")
            addOutputLine("HOME=/var/root")
        } else {
            addOutputLine("export \(args)")
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

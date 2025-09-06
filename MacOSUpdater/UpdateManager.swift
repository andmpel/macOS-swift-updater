import SwiftUI

// MARK: - Update Types
enum UpdateType: String, CaseIterable {
    case homebrew = "brew"
    case vscode = "code"
    case npm = "npm"
    case yarn = "yarn"
    case gem = "gem"
    case cargo = "cargo"
    case appStore = "mas"
    case macOS = "softwareupdate"
    
    var displayName: String {
        switch self {
        case .homebrew: return "Homebrew"
        case .vscode: return "VSCode Extensions"
        case .npm: return "npm Packages"
        case .yarn: return "Yarn Packages"
        case .gem: return "RubyGems"
        case .cargo: return "Cargo Crates"
        case .appStore: return "App Store Apps"
        case .macOS: return "macOS System"
        }
    }
    
    var description: String {
        switch self {
        case .homebrew: return "Update Homebrew formulas and casks"
        case .vscode: return "Update Visual Studio Code extensions"
        case .npm: return "Update global npm packages"
        case .yarn: return "Update yarn packages"
        case .gem: return "Update RubyGems (user install)"
        case .cargo: return "Update Rust cargo crates"
        case .appStore: return "Update Mac App Store applications"
        case .macOS: return "Install macOS system updates"
        }
    }
    
    var icon: String {
        switch self {
        case .homebrew: return "mug.fill"
        case .vscode: return "chevron.left.forwardslash.chevron.right"
        case .npm: return "cube.box.fill"
        case .yarn: return "yarn"
        case .gem: return "diamond.fill"
        case .cargo: return "shippingbox.fill"
        case .appStore: return "bag.fill"
        case .macOS: return "apple.logo"
        }
    }
    
    var color: Color {
        switch self {
        case .homebrew: return .orange
        case .vscode: return .blue
        case .npm: return .red
        case .yarn: return .blue
        case .gem: return .red
        case .cargo: return .orange
        case .appStore: return .blue
        case .macOS: return .gray
        }
    }
    
    var commands: [String] {
        switch self {
        case .homebrew:
            return [
                "brew update",
                "brew upgrade", 
                "brew cleanup -s",
                "brew doctor",
                "brew missing"
            ]
        case .vscode:
            return ["code --update-extensions"]
        case .npm:
            return ["npm update -g"]
        case .yarn:
            return ["yarn upgrade --latest"]
        case .gem:
            return [
                "gem update --user-install",
                "gem cleanup --user-install"
            ]
        case .cargo:
            return ["cargo install --list | grep -E '^[a-z0-9_-]+ v[0-9.]+:$' | cut -f1 -d' ' | xargs cargo install"]
        case .appStore:
            return ["mas upgrade"]
        case .macOS:
            return ["softwareupdate -i -a"]
        }
    }
    
    var requiresSpecialHandling: Bool {
        switch self {
        case .gem, .cargo: return true
        default: return false
        }
    }
}

// MARK: - Output Line
struct OutputLine {
    let content: String
    let type: OutputType
    let timestamp: Date
    
    enum OutputType {
        case normal
        case error
        case success
    }
}

// MARK: - Update Manager
@MainActor
class UpdateManager: ObservableObject {
    @Published var selectedUpdates: Set<UpdateType> = []
    @Published var output: [OutputLine] = []
    @Published var isUpdating: Bool = false
    @Published var hasInternetConnection: Bool = true
    @Published private var commandAvailability: [UpdateType: Bool] = [:]
    
    init() {
        // Initialize with empty state
    }
    
    // MARK: - Command Availability
    func isCommandAvailable(for updateType: UpdateType) -> Bool {
        return commandAvailability[updateType] ?? false
    }
    
    func checkCommandAvailability() {
        Task {
            var availability: [UpdateType: Bool] = [:]
            
            for updateType in UpdateType.allCases {
                let isAvailable: Bool
                
                if updateType == .gem {
                    // Special handling for gem - check if it's not the system gem
                    do {
                        let result = try await ShellExecutor.execute(command: "which gem")
                        let gemPath = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                        isAvailable = result.exitCode == 0 && !gemPath.contains("/usr/bin/gem")
                    } catch {
                        isAvailable = false
                    }
                } else {
                    isAvailable = await ShellExecutor.isCommandAvailable(updateType.rawValue)
                }
                
                availability[updateType] = isAvailable
            }
            
            commandAvailability = availability
        }
    }
    
    func selectAllAvailableUpdates() {
        selectedUpdates = Set(UpdateType.allCases.filter { isCommandAvailable(for: $0) })
    }
    
    // MARK: - Internet Connection
    func checkInternetConnection() {
        Task {
            let hasConnection = await ShellExecutor.checkInternetConnection()
            hasInternetConnection = hasConnection
        }
    }
    
    // MARK: - Output Management
    func addOutput(_ text: String, type: OutputLine.OutputType = .normal) {
        // Handle single lines more efficiently
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            output.append(OutputLine(
                content: trimmedText,
                type: type,
                timestamp: Date()
            ))
        }
    }
    
    func clearOutput() {
        output.removeAll()
    }
    
    // MARK: - Update Execution
    func runSelectedUpdates() {
        guard !selectedUpdates.isEmpty && hasInternetConnection else { return }
        
        isUpdating = true
        clearOutput()
        
        Task {
            addOutput("📋 Selected updates: \(selectedUpdates.map { $0.displayName }.joined(separator: ", "))")
            addOutput(String(repeating: "=", count: 60))
            
            for updateType in UpdateType.allCases {
                if selectedUpdates.contains(updateType) {
                    await runUpdate(for: updateType)
                    addOutput("") // Add spacing between different update types
                }
            }
            
            addOutput(String(repeating: "=", count: 60))
            addOutput("✅ Update process completed!")
            isUpdating = false
        }
    }
    
    private func runUpdate(for updateType: UpdateType) async {
        guard isCommandAvailable(for: updateType) else {
            addOutput("❌ \(updateType.displayName): Command '\(updateType.rawValue)' not available", type: .error)
            return
        }
        
        addOutput("🔄 Updating \(updateType.displayName)...")
        
        for command in updateType.commands {
            addOutput("$ \(command)")
            
            do {
                _ = try await ShellExecutor.executeWithStreaming(
                    command: command
                ) { [weak self] output in
                    self?.addOutput(output)
                }
            } catch {
                addOutput("❌ Error executing command: \(error.localizedDescription)", type: .error)
            }
            
            // Add small delay between commands
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        addOutput("✅ \(updateType.displayName) update completed")
    }
}

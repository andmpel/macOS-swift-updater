import Foundation

struct ShellExecutor {
    static func execute(command: String, arguments: [String] = [], environment: [String: String]? = nil) async throws -> (output: String, error: String, exitCode: Int32) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            
            // Use login shell to get proper environment
            let fullCommand = arguments.isEmpty ? command : "\(command) \(arguments.joined(separator: " "))"
            process.arguments = ["-l", "-c", fullCommand]
            
            // Set up environment by inheriting from login shell
            var processEnv = ProcessInfo.processInfo.environment
            
            // Let the login shell handle PATH setup
            processEnv["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            
            // Add custom environment variables if provided
            if let environment = environment {
                for (key, value) in environment {
                    processEnv[key] = value
                }
            }
            
            process.environment = processEnv
            
            // Set up pipes for output and error
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            var outputData = Data()
            var errorData = Data()
            
            // Read output asynchronously
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    outputData.append(data)
                }
            }
            
            // Read error asynchronously
            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    errorData.append(data)
                }
            }
            
            process.terminationHandler = { process in
                // Close the file handles
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""
                
                continuation.resume(returning: (output: output, error: error, exitCode: process.terminationStatus))
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func isCommandAvailable(_ command: String) async -> Bool {
        do {
            let result = try await execute(command: "command", arguments: ["-v", command])
            return result.exitCode == 0
        } catch {
            return false
        }
    }
    
    static func checkInternetConnection() async -> Bool {
        do {
            let result = try await execute(
                command: "curl",
                arguments: ["-Is", "--connect-timeout", "5", "--max-time", "10", "https://www.google.com"]
            )
            return result.exitCode == 0 && result.output.contains("200")
        } catch {
            return false
        }
    }
}

// Extension for streaming output
extension ShellExecutor {
    static func executeWithStreaming(
        command: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        outputHandler: @escaping (String) -> Void
    ) async throws -> Int32 {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            
            // Use login shell to get proper environment
            let fullCommand = arguments.isEmpty ? command : "\(command) \(arguments.joined(separator: " "))"
            process.arguments = ["-l", "-c", fullCommand]
            
            // Set up environment by inheriting from login shell
            var processEnv = ProcessInfo.processInfo.environment
            
            // Let the login shell handle PATH setup
            processEnv["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
            
            // Add custom environment variables if provided
            if let environment = environment {
                for (key, value) in environment {
                    processEnv[key] = value
                }
            }
            
            process.environment = processEnv
            
            let outputPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = outputPipe  // Combine stderr with stdout to avoid duplicates
            
            // Stream combined output in real-time
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        // Split by lines and send each line separately for cleaner output
                        let lines = string.components(separatedBy: .newlines)
                        for line in lines {
                            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                            if !trimmedLine.isEmpty {
                                outputHandler(trimmedLine)
                            }
                        }
                    }
                }
            }
            
            process.terminationHandler = { process in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: process.terminationStatus)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

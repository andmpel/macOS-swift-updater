import SwiftUI

struct ContentView: View {
    @StateObject private var updateManager = UpdateManager()
    
    var body: some View {
        HSplitView {
            // Left panel - Update options
            VStack(alignment: .leading, spacing: 20) {
                Text("macOS System Updater")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select updates to run:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(UpdateType.allCases, id: \.self) { updateType in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { updateManager.selectedUpdates.contains(updateType) },
                                set: { isSelected in
                                    if isSelected {
                                        updateManager.selectedUpdates.insert(updateType)
                                    } else {
                                        updateManager.selectedUpdates.remove(updateType)
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: updateType.icon)
                                        .foregroundColor(updateType.color)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(updateType.displayName)
                                            .fontWeight(.medium)
                                        Text(updateType.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .toggleStyle(.checkbox)
                            .disabled(!updateManager.isCommandAvailable(for: updateType))
                            
                            Spacer()
                            
                            if !updateManager.isCommandAvailable(for: updateType) {
                                Text("Not Available")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if updateManager.isUpdating && updateManager.selectedUpdates.contains(updateType) {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack {
                    Button("Select All") {
                        updateManager.selectAllAvailableUpdates()
                    }
                    .disabled(updateManager.isUpdating)
                    
                    Button("Deselect All") {
                        updateManager.selectedUpdates.removeAll()
                    }
                    .disabled(updateManager.isUpdating)
                    
                    Spacer()
                    
                    Button("Check Internet") {
                        updateManager.checkInternetConnection()
                    }
                    .disabled(updateManager.isUpdating)
                }
                
                Button(action: {
                    updateManager.runSelectedUpdates()
                }) {
                    HStack {
                        if updateManager.isUpdating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(updateManager.isUpdating ? "Updating..." : "Run Updates")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(updateManager.selectedUpdates.isEmpty || updateManager.isUpdating)
                
                if !updateManager.hasInternetConnection {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                        Text("No internet connection detected")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 350, maxWidth: 400)
            
            // Right panel - Output
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Output")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Clear") {
                        updateManager.clearOutput()
                    }
                    .disabled(updateManager.isUpdating)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(updateManager.output.enumerated()), id: \.offset) { index, line in
                                HStack {
                                    Text(line.content)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(line.type == .error ? .red : .primary)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                                .padding(.vertical, 1)
                                .id(index)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .border(Color.gray.opacity(0.3))
                    .onChange(of: updateManager.output.count) { _ in
                        if let lastIndex = updateManager.output.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            updateManager.checkCommandAvailability()
            updateManager.checkInternetConnection()
        }
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct SettingsView: View {
    @ObservedObject var envoyService: EnvoyService
    @State private var apiKey: String = ""
    @State private var locationID: String = ""
    @State private var printerURL: String = ""
    @State private var showSaved: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter Envoy API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter Envoy Location ID", text: $locationID)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Envoy API Configuration")
                } footer: {
                    Text("Get your API key from the Envoy dashboard under Settings > Integrations > API.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Printer URL (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., ipps://printer.local:631/ipp/print", text: $printerURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Printer Configuration")
                } footer: {
                    Text("Leave blank to use AirPrint picker. Set a URL for silent/automatic printing in kiosk mode.")
                }

                Section {
                    HStack {
                        Text("Envoy Status")
                        Spacer()
                        if envoyService.isConfigured {
                            Label("Configured", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Not Configured", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } header: {
                    Text("Status")
                }

                Section {
                    Button("Save Settings") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSaved {
                    VStack {
                        Spacer()
                        Label("Settings Saved", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                apiKey = UserDefaults.standard.string(forKey: "envoy_api_key") ?? ""
                locationID = UserDefaults.standard.string(forKey: "envoy_location_id") ?? ""
                printerURL = UserDefaults.standard.string(forKey: "printer_url") ?? ""
            }
        }
    }

    private func saveSettings() {
        envoyService.configure(apiKey: apiKey, locationID: locationID)
        UserDefaults.standard.set(printerURL, forKey: "printer_url")

        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaved = false
            }
        }
    }
}

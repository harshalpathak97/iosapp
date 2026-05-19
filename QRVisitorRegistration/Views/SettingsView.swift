import SwiftUI

struct SettingsView: View {
    @ObservedObject var envoyService: EnvoyService
    @ObservedObject var scraperService: LinkedInScraperService

    @State private var apiKey: String = ""
    @State private var locationID: String = ""
    @State private var printerURL: String = ""
    @State private var scraperBackendURL: String = ""
    @State private var scraperSharedSecret: String = ""
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
                        Text("Backend URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("e.g., https://your-server.com or http://192.168.1.42:3000", text: $scraperBackendURL)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.URL)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shared Secret")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("Enter shared secret (API_SHARED_SECRET)", text: $scraperSharedSecret)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("LinkedIn Scraper Backend")
                } footer: {
                    Text("Optional. When a scanned LinkedIn URL is not in the local attendees database, the app will call this backend to scrape the profile. See backend/README.md.")
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
                        Text("Envoy")
                        Spacer()
                        if envoyService.isConfigured {
                            Label("Configured", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Not Configured", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    HStack {
                        Text("LinkedIn Scraper")
                        Spacer()
                        if scraperService.isConfigured {
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
                scraperBackendURL = UserDefaults.standard.string(forKey: "scraper_backend_url") ?? ""
                scraperSharedSecret = UserDefaults.standard.string(forKey: "scraper_shared_secret") ?? ""
            }
        }
    }

    private func saveSettings() {
        envoyService.configure(apiKey: apiKey, locationID: locationID)
        scraperService.configure(backendURL: scraperBackendURL, sharedSecret: scraperSharedSecret)
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

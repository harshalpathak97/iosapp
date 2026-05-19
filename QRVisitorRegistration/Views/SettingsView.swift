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
                statusSection
                envoySection
                scraperSection
                printerSection
                saveSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                }
            }
            .overlay(alignment: .bottom) {
                if showSaved {
                    savedToast
                        .padding(.bottom, DS.Spacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear(perform: loadFields)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        Section {
            statusRow(
                label: "Envoy Integration",
                subtitle: envoyService.isConfigured ? "Ready to sync visitors" : "Add your API key to enable",
                kind: envoyService.isConfigured ? .success : .warning
            )
            statusRow(
                label: "LinkedIn Scraper",
                subtitle: scraperService.isConfigured ? "Fallback active for unknown profiles" : "Optional - configure for walk-ins",
                kind: scraperService.isConfigured ? .success : .neutral
            )
        } header: {
            Text("Status")
        }
    }

    private func statusRow(label: String, subtitle: String, kind: StatusPill.Kind) -> some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: kind.icon)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(kind.color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DS.Color.textSecondary)
            }
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    // MARK: - Envoy

    private var envoySection: some View {
        Section {
            labeledField(label: "API Key", placeholder: "Paste your Envoy API key", text: $apiKey, isSecure: true)
            labeledField(label: "Location ID", placeholder: "Numeric location ID", text: $locationID)
        } header: {
            Text("Envoy API")
        } footer: {
            Text("Get your credentials from the Envoy dashboard under Settings > Integrations > API. The Envoy kiosk app uses the same location ID.")
        }
    }

    // MARK: - Scraper

    private var scraperSection: some View {
        Section {
            labeledField(label: "Backend URL", placeholder: "https://your-server.com", text: $scraperBackendURL, keyboard: .URL)
            labeledField(label: "Shared Secret", placeholder: "Long random string", text: $scraperSharedSecret, isSecure: true)
        } header: {
            Text("LinkedIn Scraper Backend (Optional)")
        } footer: {
            Text("When a scanned LinkedIn URL is not in the local attendee list, the app will call this backend to fetch the profile. See backend/README.md in the repo.")
        }
    }

    // MARK: - Printer

    private var printerSection: some View {
        Section {
            labeledField(label: "Printer URL", placeholder: "ipps://printer.local:631/ipp/print", text: $printerURL, keyboard: .URL)
        } header: {
            Text("Printer (Optional)")
        } footer: {
            Text("Leave blank to use the AirPrint picker. Set a URL for silent automatic printing in kiosk mode.")
        }
    }

    // MARK: - Save

    private var saveSection: some View {
        Section {
            Button(action: saveSettings) {
                Label("Save Settings", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .listRowInsets(EdgeInsets(top: DS.Spacing.s, leading: 0, bottom: DS.Spacing.s, trailing: 0))
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Reusable field

    private func labeledField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(DS.Color.textTertiary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .font(.body)
            .padding(.vertical, DS.Spacing.s)
            .padding(.horizontal, DS.Spacing.s)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.s))
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DS.Color.success)
            Text("Settings Saved")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.s)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    // MARK: - Logic

    private func loadFields() {
        apiKey = UserDefaults.standard.string(forKey: DS.Keys.envoyAPIKey) ?? ""
        locationID = UserDefaults.standard.string(forKey: DS.Keys.envoyLocationID) ?? ""
        printerURL = UserDefaults.standard.string(forKey: DS.Keys.printerURL) ?? ""
        scraperBackendURL = UserDefaults.standard.string(forKey: DS.Keys.scraperBackendURL) ?? ""
        scraperSharedSecret = UserDefaults.standard.string(forKey: DS.Keys.scraperSharedSecret) ?? ""
    }

    private func saveSettings() {
        envoyService.configure(apiKey: apiKey, locationID: locationID)
        scraperService.configure(backendURL: scraperBackendURL, sharedSecret: scraperSharedSecret)
        UserDefaults.standard.set(printerURL, forKey: DS.Keys.printerURL)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(DS.Animation.snappy) {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(DS.Animation.smooth) {
                showSaved = false
            }
        }
    }
}

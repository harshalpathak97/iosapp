import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @State private var selectedTab: Tab = .scanner
    @State private var showSettings: Bool = false

    enum Tab: String, CaseIterable {
        case scanner = "Scanner"
        case attendees = "Attendees"
        case log = "Log"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            Divider()

            // Main content based on tab
            Group {
                switch selectedTab {
                case .scanner:
                    scannerContent
                case .attendees:
                    DashboardView(viewModel: viewModel)
                case .log:
                    RegistrationLogView(records: viewModel.registrationLog)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Status bar
            if !viewModel.statusMessage.isEmpty {
                statusBar
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                envoyService: viewModel.envoyService,
                scraperService: viewModel.scraperService
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 20) {
            // App title
            HStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("QR Visitor Registration")
                    .font(.title2.bold())
            }

            Spacer()

            // Tab picker
            Picker("View", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tabIcon(for: tab))
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 360)

            Spacer()

            // Settings button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.title3)
            }

            // Envoy status indicator
            Circle()
                .fill(viewModel.envoyService.isConfigured ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Scanner Content

    private var scannerContent: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700

            if isWide {
                // iPad landscape: side-by-side layout
                HStack(spacing: 0) {
                    // Left: QR Scanner
                    scannerPanel
                        .frame(width: geometry.size.width * 0.5)

                    Divider()

                    // Right: Result panel
                    resultPanel
                        .frame(width: geometry.size.width * 0.5)
                }
            } else {
                // Portrait or compact: stacked
                ZStack {
                    scannerPanel

                    if case .scanning = viewModel.currentState {
                        // Show scanner full screen
                    } else {
                        resultPanel
                            .background(Color(.systemBackground))
                    }
                }
            }
        }
    }

    private var scannerPanel: some View {
        ZStack {
            QRScannerView(
                scannedCode: Binding(
                    get: { viewModel.scannedCode },
                    set: { newValue in
                        if let code = newValue {
                            Task { await viewModel.processScannedCode(code) }
                        }
                    }
                ),
                isScanning: $viewModel.isScanning
            )

            // Overlay when not scanning
            if !viewModel.isScanning {
                Color.black.opacity(0.4)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("QR Code Scanned")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                    )
            }
        }
    }

    @ViewBuilder
    private var resultPanel: some View {
        switch viewModel.currentState {
        case .scanning:
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Scan a LinkedIn QR code to begin")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .attendeeFound(let attendee), .completed(let attendee):
            let isCompleted = {
                if case .completed = viewModel.currentState { return true }
                return false
            }()

            AttendeeDetailView(
                attendee: attendee,
                onRegister: {
                    Task {
                        await viewModel.registerAttendee(attendee)
                    }
                },
                onPrintBadge: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        viewModel.printBadge(for: attendee, from: rootVC)
                    }
                },
                onCancel: {
                    viewModel.resetToScanning()
                },
                isLoading: viewModel.isLoading,
                isCompleted: isCompleted
            )

        case .scrapingProfile(let url):
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Looking up LinkedIn profile...")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text(url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                Text("This can take 10-30 seconds")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .notFound(let url):
            VStack(spacing: 20) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                Text("Attendee Not Found")
                    .font(.title.bold())

                Text("No attendee matches the LinkedIn profile:")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text(url)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)

                Button {
                    viewModel.resetToScanning()
                } label: {
                    Label("Scan Again", systemImage: "qrcode.viewfinder")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: 300, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .registering:
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Registering visitor...")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let message):
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                Text("Error")
                    .font(.title.bold())
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.resetToScanning()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: 300, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Helpers

    private func tabIcon(for tab: Tab) -> String {
        switch tab {
        case .scanner: return "qrcode.viewfinder"
        case .attendees: return "person.3"
        case .log: return "list.clipboard"
        }
    }
}

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

        var icon: String {
            switch self {
            case .scanner: return "qrcode.viewfinder"
            case .attendees: return "person.2.fill"
            case .log: return "list.bullet.clipboard.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
                .opacity(0.3)

            Group {
                switch selectedTab {
                case .scanner:
                    scannerContent
                        .transition(.opacity)
                case .attendees:
                    DashboardView(viewModel: viewModel)
                        .transition(.opacity)
                case .log:
                    RegistrationLogView(records: viewModel.registrationLog)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(DS.Animation.smooth, value: selectedTab)

            if !viewModel.statusMessage.isEmpty {
                statusBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DS.Animation.smooth, value: viewModel.statusMessage)
        .sheet(isPresented: $showSettings) {
            SettingsView(
                envoyService: viewModel.envoyService,
                scraperService: viewModel.scraperService
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: DS.Spacing.l) {
            HStack(spacing: DS.Spacing.s) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                    .foregroundStyle(DS.Gradient.primary)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Visitor Registration")
                        .font(.title3.bold())
                        .foregroundColor(DS.Color.textPrimary)
                    Text("LinkedIn QR Scanner")
                        .font(.caption)
                        .foregroundColor(DS.Color.textSecondary)
                }
            }

            Spacer()

            Picker("View", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)

            Spacer()

            HStack(spacing: DS.Spacing.s) {
                serviceStatusDot(
                    isOn: viewModel.envoyService.isConfigured,
                    label: "Envoy"
                )
                serviceStatusDot(
                    isOn: viewModel.scraperService.isConfigured,
                    label: "Scraper"
                )

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(DS.Color.textSecondary)
                        .padding(DS.Spacing.xs)
                        .background(Circle().fill(DS.Color.surface))
                }
            }
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.s)
        .background(DS.Color.background)
    }

    private func serviceStatusDot(isOn: Bool, label: String) -> some View {
        HStack(spacing: DS.Spacing.xxs) {
            Circle()
                .fill(isOn ? DS.Color.success : DS.Color.textTertiary.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(DS.Color.textSecondary)
        }
    }

    // MARK: - Scanner Content

    private var scannerContent: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > 700

            if isWide {
                HStack(spacing: 0) {
                    scannerPanel
                        .frame(width: geometry.size.width * 0.5)

                    Divider().opacity(0.3)

                    resultPanel
                        .frame(width: geometry.size.width * 0.5)
                        .background(DS.Color.background)
                }
            } else {
                ZStack {
                    scannerPanel
                    if case .scanning = viewModel.currentState {
                        EmptyView()
                    } else {
                        resultPanel
                            .background(DS.Color.background)
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

            if !viewModel.isScanning {
                Color.black.opacity(0.55)
                    .overlay(
                        VStack(spacing: DS.Spacing.m) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(DS.Color.success, .white)
                                .symbolRenderingMode(.palette)
                            Text("QR Code Captured")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    )
                    .transition(.opacity)
            }
        }
        .animation(DS.Animation.smooth, value: viewModel.isScanning)
    }

    @ViewBuilder
    private var resultPanel: some View {
        switch viewModel.currentState {
        case .scanning:
            EmptyStateView(
                icon: "qrcode.viewfinder",
                title: "Ready to Scan",
                subtitle: "Point the camera at a LinkedIn QR code to look up the attendee."
            )
            .padding(DS.Spacing.l)

        case .attendeeFound(let attendee), .completed(let attendee):
            let isCompleted: Bool = {
                if case .completed = viewModel.currentState { return true }
                return false
            }()

            AttendeeDetailView(
                attendee: attendee,
                onRegister: {
                    Task { await viewModel.registerAttendee(attendee) }
                },
                onPrintBadge: {
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = scene.windows.first?.rootViewController {
                        viewModel.printBadge(for: attendee, from: rootVC)
                    }
                },
                onCancel: { viewModel.resetToScanning() },
                isLoading: viewModel.isLoading,
                isCompleted: isCompleted
            )
            .transition(.move(edge: .trailing).combined(with: .opacity))

        case .scrapingProfile(let url):
            VStack(spacing: DS.Spacing.l) {
                ZStack {
                    Circle()
                        .stroke(DS.Color.primary.opacity(0.15), lineWidth: 6)
                        .frame(width: 96, height: 96)
                    ProgressView()
                        .scaleEffect(1.8)
                        .tint(DS.Color.primary)
                }

                VStack(spacing: DS.Spacing.xs) {
                    Text("Fetching LinkedIn Profile")
                        .font(.title2.bold())
                    Text("Scraping the profile via your backend")
                        .font(.body)
                        .foregroundColor(DS.Color.textSecondary)
                }

                Text(url)
                    .font(.caption.monospaced())
                    .foregroundColor(DS.Color.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Color.surface, in: Capsule())

                StatusPill(kind: .info, text: "This can take 10-30 seconds")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DS.Spacing.l)
            .transition(.opacity)

        case .notFound(let url):
            VStack(spacing: DS.Spacing.l) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(DS.Color.warning)

                VStack(spacing: DS.Spacing.xs) {
                    Text("Attendee Not Found")
                        .font(.title.bold())
                    Text("No record matches this LinkedIn profile.")
                        .font(.body)
                        .foregroundColor(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Text(url)
                    .font(.caption.monospaced())
                    .foregroundColor(DS.Color.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, DS.Spacing.m)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(DS.Color.primary.opacity(0.08), in: Capsule())

                Button {
                    viewModel.resetToScanning()
                } label: {
                    Label("Scan Again", systemImage: "qrcode.viewfinder")
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .frame(maxWidth: 340)
                .padding(.top, DS.Spacing.s)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DS.Spacing.l)
            .transition(.opacity)

        case .registering:
            VStack(spacing: DS.Spacing.l) {
                ProgressView()
                    .scaleEffect(1.8)
                    .tint(DS.Color.primary)
                Text("Registering visitor...")
                    .font(.title2.bold())
                Text("Sending to Envoy")
                    .font(.body)
                    .foregroundColor(DS.Color.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DS.Spacing.l)

        case .error(let message):
            VStack(spacing: DS.Spacing.l) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(DS.Color.danger)
                Text("Something Went Wrong")
                    .font(.title.bold())
                Text(message)
                    .font(.body)
                    .foregroundColor(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.l)

                Button {
                    viewModel.resetToScanning()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryActionButtonStyle(tint: DS.Color.danger))
                .frame(maxWidth: 340)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DS.Spacing.l)
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "info.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(DS.Color.primary)
            Text(viewModel.statusMessage)
                .font(.subheadline)
                .foregroundColor(DS.Color.textSecondary)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.s)
        .background(DS.Color.surface)
    }
}

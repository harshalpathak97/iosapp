import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @State private var searchText: String = ""

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailContent
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().opacity(0.3)
            attendeeList
        }
        .background(DS.Color.background)
        .navigationTitle("Attendees")
        .navigationBarTitleDisplayMode(.large)
    }

    private var searchBar: some View {
        HStack(spacing: DS.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DS.Color.textTertiary)
            TextField("Search by name, company, or title", text: $searchText)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.Color.textTertiary)
                }
            }
        }
        .padding(DS.Spacing.s)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.m))
        .padding(.horizontal, DS.Spacing.m)
        .padding(.vertical, DS.Spacing.s)
    }

    private var attendeeList: some View {
        let filtered = viewModel.database.searchAttendees(query: searchText)
        return Group {
            if filtered.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Matches",
                    subtitle: searchText.isEmpty
                        ? "The attendee database is empty."
                        : "No attendees match \"\(searchText)\"."
                )
            } else {
                List {
                    ForEach(filtered) { attendee in
                        Button {
                            viewModel.matchedAttendee = attendee
                            viewModel.currentState = .attendeeFound(attendee)
                        } label: {
                            attendeeRow(attendee)
                        }
                        .listRowBackground(DS.Color.background)
                        .listRowSeparatorTint(DS.Color.divider.opacity(0.5))
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func attendeeRow(_ attendee: Attendee) -> some View {
        HStack(spacing: DS.Spacing.s) {
            InitialsAvatar(name: attendee.name, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(attendee.name)
                    .font(.headline)
                    .foregroundColor(DS.Color.textPrimary)
                Text(attendee.title)
                    .font(.subheadline)
                    .foregroundColor(DS.Color.textSecondary)
                    .lineLimit(1)
                Text(attendee.company)
                    .font(.caption)
                    .foregroundColor(DS.Color.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(DS.Color.textTertiary)
        }
        .padding(.vertical, DS.Spacing.xxs)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        switch viewModel.currentState {
        case .attendeeFound(let attendee):
            attendeeDetailContent(attendee: attendee, isCompleted: false)
        case .completed(let attendee):
            attendeeDetailContent(attendee: attendee, isCompleted: true)
        default:
            EmptyStateView(
                icon: "person.crop.rectangle.stack",
                title: "Select an Attendee",
                subtitle: "Pick someone from the list to see their details, or scan a QR code from the Scanner tab."
            )
            .padding(DS.Spacing.l)
        }
    }

    @ViewBuilder
    private func attendeeDetailContent(attendee: Attendee, isCompleted: Bool) -> some View {
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
    }
}

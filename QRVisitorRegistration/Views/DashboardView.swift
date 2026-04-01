import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @State private var searchText: String = ""

    var body: some View {
        NavigationSplitView {
            // Sidebar: Attendee list
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search attendees...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Attendee list
                let filtered = viewModel.database.searchAttendees(query: searchText)
                List(filtered) { attendee in
                    Button {
                        viewModel.matchedAttendee = attendee
                        viewModel.currentState = .attendeeFound(attendee)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(attendee.name)
                                .font(.headline)
                            Text(attendee.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(attendee.company)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Attendees (\(viewModel.database.attendees.count))")

        } detail: {
            // Detail: current state
            switch viewModel.currentState {
            case .scanning:
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select an attendee or scan a QR code")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            case .attendeeFound(let attendee):
                attendeeDetailContent(attendee: attendee, isCompleted: false)
            case .completed(let attendee):
                attendeeDetailContent(attendee: attendee, isCompleted: true)
            default:
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Select an attendee")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func attendeeDetailContent(attendee: Attendee, isCompleted: Bool) -> some View {
        AttendeeDetailView(
            attendee: attendee,
            onRegister: {
                Task {
                    await viewModel.registerAttendee(attendee)
                }
            },
            onPrintBadge: {
                // Print will be triggered from the hosting view controller
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
    }
}

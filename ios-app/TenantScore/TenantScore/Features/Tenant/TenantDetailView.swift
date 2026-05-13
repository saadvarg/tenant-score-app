import SwiftUI

struct TenantDetailView: View {
    let tenant: Tenant
    @ObservedObject var viewModel: TenantViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditForm = false
    @State private var isShowingDeleteConfirmation = false
    @State private var decisionNote = ""
    @State private var events: [TenantEvent] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                riskPanel
                decisionPanel
                recommendationPanel
                factorsPanel
                applicantPanel
                financialPanel
                historyPanel
                activityPanel

                if let notes = tenant.notes, !notes.isEmpty {
                    DetailCard(title: "Notes") {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(tenant.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") {
                        isShowingEditForm = true
                    }

                    Button("Delete", role: .destructive) {
                        isShowingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingEditForm) {
            TenantFormView(viewModel: viewModel, tenant: tenant)
        }
        .confirmationDialog("Delete tenant?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTenant(tenant)
                    dismiss()
                }
            }
        }
        .task {
            events = await viewModel.loadEvents(for: tenant)
        }
    }

    private var riskPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(tenant.riskScore)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(tenant.riskLevel.color)

                Text("/ 100")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(tenant.riskLevel.title) Risk")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tenant.riskLevel.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(tenant.riskLevel.color.opacity(0.12))
                    .clipShape(Capsule())
            }

            ProgressView(value: Double(tenant.riskScore), total: 100)
                .tint(tenant.riskLevel.color)
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var recommendationPanel: some View {
        DetailCard(title: "Recommendation") {
            HStack(spacing: 12) {
                Image(systemName: tenant.recommendation.symbolName)
                    .font(.title2)
                    .foregroundStyle(tenant.recommendation.color)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tenant.recommendation.title)
                        .font(.headline)
                        .foregroundStyle(tenant.recommendation.color)

                    Text(tenant.recommendation.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var decisionPanel: some View {
        DetailCard(title: "Decision") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Current Status")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(tenant.applicationStatus.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tenant.applicationStatus.color)
                }

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.updateStatus(for: tenant, status: .approved, note: decisionNote.nilIfBlank)
                            dismiss()
                        }
                    } label: {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.updateStatus(for: tenant, status: .rejected, note: decisionNote.nilIfBlank)
                            dismiss()
                        }
                    } label: {
                        Label("Reject", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                TextField("Optional decision note", text: $decisionNote, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)

                if tenant.applicationStatus != .pending {
                    Button {
                        Task {
                            await viewModel.updateStatus(for: tenant, status: .pending, note: decisionNote.nilIfBlank)
                            dismiss()
                        }
                    } label: {
                        Label("Move Back to Pending", systemImage: "clock.arrow.circlepath")
                    }
                    .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private var factorsPanel: some View {
        DetailCard(title: "Score Factors") {
            VStack(spacing: 10) {
                ForEach(tenant.scoreFactors) { factor in
                    HStack(alignment: .top, spacing: 12) {
                        Text(factor.impact > 0 ? "+\(factor.impact)" : "\(factor.impact)")
                            .font(.caption.bold())
                            .foregroundStyle(factor.impact >= 0 ? .green : .red)
                            .frame(width: 42, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(factor.label)
                                .font(.subheadline.weight(.semibold))

                            Text(factor.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var applicantPanel: some View {
        DetailCard(title: "Applicant") {
            DetailLine(label: "Email", value: tenant.email ?? "Not provided")
            DetailLine(label: "Phone", value: tenant.phone ?? "Not provided")
            DetailLine(label: "Employment", value: tenant.employmentStatus.title)
        }
    }

    private var financialPanel: some View {
        DetailCard(title: "Financials") {
            DetailLine(label: "Monthly Income", value: "$\(tenant.monthlyIncome.formattedNumber)")
            DetailLine(label: "Rent Amount", value: "$\(tenant.rentAmount.formattedNumber)")
            DetailLine(label: "Credit Score", value: "\(tenant.creditScore)")
        }
    }

    private var historyPanel: some View {
        DetailCard(title: "History") {
            DetailLine(label: "Evictions", value: "\(tenant.evictionCount)")
            DetailLine(label: "Late Payments", value: "\(tenant.latePayments)")
            DetailLine(label: "Criminal Record", value: tenant.criminalRecord ? "Yes" : "No")
        }
    }

    private var activityPanel: some View {
        DetailCard(title: "Activity") {
            if events.isEmpty {
                Text("No activity yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(events) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: event.symbolName)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(event.message)
                                    .font(.subheadline.weight(.medium))

                                Text(event.actorEmail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

private extension TenantEvent {
    var symbolName: String {
        switch eventType {
        case "created":
            return "plus.circle.fill"
        case "updated":
            return "pencil.circle.fill"
        case "status_changed":
            return "checkmark.seal.fill"
        default:
            return "circle.fill"
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Recommendation {
    var color: Color {
        switch self {
        case .approve:
            return .green
        case .review:
            return .orange
        case .reject:
            return .red
        }
    }

    var symbolName: String {
        switch self {
        case .approve:
            return "checkmark.seal.fill"
        case .review:
            return "exclamationmark.triangle.fill"
        case .reject:
            return "xmark.octagon.fill"
        }
    }

    var description: String {
        switch self {
        case .approve:
            return "Applicant appears strong based on current screening inputs."
        case .review:
            return "Applicant needs additional verification before approval."
        case .reject:
            return "Applicant presents elevated risk based on current screening inputs."
        }
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DetailLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

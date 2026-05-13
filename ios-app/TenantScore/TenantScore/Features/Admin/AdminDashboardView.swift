import SwiftUI

struct AdminDashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedSection: AdminSection = .overview

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        Picker("Admin section", selection: $selectedSection) {
                            ForEach(AdminSection.allCases) { section in
                                Text(section.title).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                        }

                        switch selectedSection {
                        case .overview:
                            overview
                        case .tenants:
                            tenants
                        case .users:
                            users
                        }
                    }
                    .padding(18)
                }
                .searchable(text: $viewModel.searchText, prompt: "Search platform")
                .refreshable {
                    await viewModel.load()
                }
            }
            .navigationTitle("Admin")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        authViewModel.logout()
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Platform Control")
                .font(.largeTitle.bold())

            Text(authViewModel.user?.email ?? "TenantScore administration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var overview: some View {
        if let stats = viewModel.stats {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AdminStatCard(title: "Users", value: "\(stats.totalUsers)", tint: .blue)
                    AdminStatCard(title: "Landlords", value: "\(stats.landlords)", tint: .indigo)
                }

                HStack(spacing: 12) {
                    AdminStatCard(title: "Tenants", value: "\(stats.totalTenants)", tint: .green)
                    AdminStatCard(title: "Avg Score", value: "\(stats.averageScore)", tint: .mint)
                }

                HStack(spacing: 12) {
                    AdminStatCard(title: "Low", value: "\(stats.lowRisk)", tint: .green)
                    AdminStatCard(title: "Medium", value: "\(stats.mediumRisk)", tint: .orange)
                    AdminStatCard(title: "High", value: "\(stats.highRisk)", tint: .red)
                }

                HStack(spacing: 12) {
                    AdminStatCard(title: "Pending", value: "\(stats.pendingApplications)", tint: .orange)
                    AdminStatCard(title: "Approved", value: "\(stats.approvedApplications)", tint: .green)
                    AdminStatCard(title: "Rejected", value: "\(stats.rejectedApplications)", tint: .red)
                }
            }
        } else if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }

    private var tenants: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Risk", selection: $viewModel.selectedRiskFilter) {
                ForEach(TenantRiskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            ForEach(viewModel.filteredTenants) { tenant in
                NavigationLink {
                    AdminTenantDetailView(tenant: tenant, viewModel: viewModel)
                } label: {
                    AdminTenantRow(tenant: tenant) {
                        Task {
                            await viewModel.deleteTenant(tenant)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var users: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.filteredUsers) { user in
                AdminUserRow(user: user)
            }
        }
    }
}

private enum AdminSection: String, CaseIterable, Identifiable {
    case overview
    case tenants
    case users

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private struct AdminStatCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AdminTenantRow: View {
    let tenant: Tenant
    let onDelete: () -> Void
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tenant.riskLevel.color.opacity(0.16))
                    Text("\(tenant.riskScore)")
                        .font(.headline.bold())
                        .foregroundStyle(tenant.riskLevel.color)
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(tenant.fullName)
                        .font(.headline)

                    Text(tenant.landlordEmail ?? "Unknown landlord")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(tenant.riskLevel.title) risk · \(tenant.applicationStatus.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tenant.applicationStatus.color)
                }

                Spacer()

                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .confirmationDialog("Delete this tenant application?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}

private struct AdminUserRow: View {
    let user: AdminUser

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: user.role == "admin" ? "shield.fill" : "person.fill")
                .foregroundStyle(user.role == "admin" ? .purple : .blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.email)
                    .font(.headline)
                    .lineLimit(1)

                Text("\(user.role.capitalized) · \(user.tenantCount) tenant applications")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AdminTenantDetailView: View {
    let tenant: Tenant
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var events: [TenantEvent] = []
    @State private var isConfirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(tenant.riskScore)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(tenant.riskLevel.color)

                        Text("/ 100")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(tenant.applicationStatus.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(tenant.applicationStatus.color)
                    }

                    Text("\(tenant.riskLevel.title) risk · \(tenant.recommendation.title)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(tenant.riskScore), total: 100)
                        .tint(tenant.riskLevel.color)
                }
                .padding(18)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                DetailCard(title: "Landlord") {
                    Text(tenant.landlordEmail ?? "Unknown landlord")
                        .foregroundStyle(.secondary)
                }

                DetailCard(title: "Applicant") {
                    AdminDetailLine(label: "Email", value: tenant.email ?? "Not provided")
                    AdminDetailLine(label: "Phone", value: tenant.phone ?? "Not provided")
                    AdminDetailLine(label: "Employment", value: tenant.employmentStatus.title)
                }

                DetailCard(title: "Activity") {
                    if events.isEmpty {
                        Text("No activity yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(events) { event in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(event.message)
                                        .font(.subheadline.weight(.medium))
                                    Text(event.actorEmail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
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
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete tenant application?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
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
}

private struct AdminDetailLine: View {
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

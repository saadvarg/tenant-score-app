import SwiftUI

struct TenantDashboardView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var tenantViewModel = TenantViewModel()
    @State private var isShowingForm = false
    @State private var isShowingAccount = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        scoreSummary

                        if let errorMessage = tenantViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 2)
                        }

                        tenantSection
                    }
                    .padding(18)
                }
                .searchable(text: $tenantViewModel.searchText, prompt: "Search tenants")
                .refreshable {
                    await tenantViewModel.loadTenants()
                }
            }
            .navigationTitle("TenantScore")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingAccount = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingForm) {
                TenantFormView(viewModel: tenantViewModel)
            }
            .sheet(isPresented: $isShowingAccount) {
                AccountView(authViewModel: authViewModel)
            }
            .task {
                await tenantViewModel.loadTenants()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Overview")
                .font(.largeTitle.bold())

            Text(authViewModel.user?.email ?? "Manage applications and screen tenants with consistent scoring.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var scoreSummary: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(title: "Tenants", value: "\(tenantViewModel.tenants.count)", tint: .blue)
                SummaryCard(title: "Avg Score", value: "\(tenantViewModel.averageScore)", tint: .green)
            }

            HStack(spacing: 12) {
                SummaryCard(title: "Low", value: "\(tenantViewModel.lowRiskCount)", tint: .green)
                SummaryCard(title: "Medium", value: "\(tenantViewModel.mediumRiskCount)", tint: .orange)
                SummaryCard(title: "High", value: "\(tenantViewModel.highRiskCount)", tint: .red)
            }
        }
    }

    @ViewBuilder
    private var tenantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Applications")
                    .font(.title2.bold())

                Spacer()

                if tenantViewModel.isLoading {
                    ProgressView()
                }
            }

            Picker("Risk", selection: $tenantViewModel.selectedRiskFilter) {
                ForEach(TenantRiskFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if tenantViewModel.tenants.isEmpty && !tenantViewModel.isLoading {
                EmptyTenantState {
                    isShowingForm = true
                }
            } else if tenantViewModel.filteredTenants.isEmpty {
                Text("No tenants match this search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tenantViewModel.filteredTenants) { tenant in
                        NavigationLink {
                            TenantDetailView(tenant: tenant, viewModel: tenantViewModel)
                        } label: {
                            TenantRowView(tenant: tenant)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct AccountView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account")
                        .font(.largeTitle.bold())

                    Text("Current TenantScore session")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    AccountLine(label: "Email", value: authViewModel.user?.email ?? "Unknown")
                    AccountLine(label: "Role", value: authViewModel.user?.role.capitalized ?? "Unknown")
                }
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button(role: .destructive) {
                    authViewModel.logout()
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Logout")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(18)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AccountLine: View {
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
    }
}

private struct SummaryCard: View {
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

private struct EmptyTenantState: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.blue)

            Text("No tenants yet")
                .font(.headline)

            Text("Create the first tenant profile to calculate a risk score.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Add Tenant", action: action)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

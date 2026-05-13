import Combine
import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published private(set) var stats: AdminStats?
    @Published private(set) var users: [AdminUser] = []
    @Published private(set) var tenants: [Tenant] = []
    @Published var searchText = ""
    @Published var selectedRiskFilter: TenantRiskFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let adminService: AdminServicing

    init(adminService: AdminServicing? = nil) {
        self.adminService = adminService ?? AdminService()
    }

    var filteredTenants: [Tenant] {
        tenants.filter { tenant in
            let matchesRisk: Bool

            switch selectedRiskFilter {
            case .all:
                matchesRisk = true
            case .low:
                matchesRisk = tenant.riskLevel == .low
            case .medium:
                matchesRisk = tenant.riskLevel == .medium
            case .high:
                matchesRisk = tenant.riskLevel == .high
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else {
                return matchesRisk
            }

            return matchesRisk && (
                tenant.fullName.localizedCaseInsensitiveContains(query) ||
                (tenant.email?.localizedCaseInsensitiveContains(query) ?? false) ||
                (tenant.landlordEmail?.localizedCaseInsensitiveContains(query) ?? false)
            )
        }
    }

    var filteredUsers: [AdminUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return users
        }

        return users.filter {
            $0.email.localizedCaseInsensitiveContains(query) ||
            $0.role.localizedCaseInsensitiveContains(query)
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            async let stats = adminService.getStats()
            async let users = adminService.listUsers()
            async let tenants = adminService.listTenants()

            self.stats = try await stats
            self.users = try await users
            self.tenants = try await tenants
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteTenant(_ tenant: Tenant) async {
        errorMessage = nil

        do {
            try await adminService.deleteTenant(id: tenant.id)
            tenants.removeAll { $0.id == tenant.id }
            stats = try await adminService.getStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

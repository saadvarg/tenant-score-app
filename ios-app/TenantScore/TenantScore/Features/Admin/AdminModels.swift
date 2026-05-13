import Foundation

struct AdminStats: Decodable {
    let totalUsers: Int
    let landlords: Int
    let admins: Int
    let totalTenants: Int
    let lowRisk: Int
    let mediumRisk: Int
    let highRisk: Int
    let pendingApplications: Int
    let approvedApplications: Int
    let rejectedApplications: Int
    let averageScore: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case landlords
        case admins
        case totalTenants = "total_tenants"
        case lowRisk = "low_risk"
        case mediumRisk = "medium_risk"
        case highRisk = "high_risk"
        case pendingApplications = "pending_applications"
        case approvedApplications = "approved_applications"
        case rejectedApplications = "rejected_applications"
        case averageScore = "average_score"
    }
}

struct AdminStatsResponse: Decodable {
    let stats: AdminStats
}

struct AdminUser: Decodable, Identifiable {
    let id: Int
    let email: String
    let role: String
    let createdAt: String
    let tenantCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case createdAt = "created_at"
        case tenantCount = "tenant_count"
    }
}

struct AdminUsersResponse: Decodable {
    let users: [AdminUser]
}

import Foundation

struct Tenant: Decodable, Identifiable, Equatable {
    let id: Int
    let landlordId: Int?
    let landlordEmail: String?
    let fullName: String
    let email: String?
    let phone: String?
    let monthlyIncome: Double
    let rentAmount: Double
    let employmentStatus: EmploymentStatus
    let creditScore: Int
    let evictionCount: Int
    let latePayments: Int
    let criminalRecord: Bool
    let notes: String?
    let riskScore: Int
    let riskLevel: RiskLevel
    let recommendation: Recommendation
    let applicationStatus: ApplicationStatus
    let scoreFactors: [ScoreFactor]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case landlordId = "landlord_id"
        case landlordEmail = "landlord_email"
        case fullName = "full_name"
        case email
        case phone
        case monthlyIncome = "monthly_income"
        case rentAmount = "rent_amount"
        case employmentStatus = "employment_status"
        case creditScore = "credit_score"
        case evictionCount = "eviction_count"
        case latePayments = "late_payments"
        case criminalRecord = "criminal_record"
        case notes
        case riskScore = "risk_score"
        case riskLevel = "risk_level"
        case recommendation
        case applicationStatus = "application_status"
        case scoreFactors = "score_factors"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        landlordId = try container.decodeIfPresent(Int.self, forKey: .landlordId)
        landlordEmail = try container.decodeIfPresent(String.self, forKey: .landlordEmail)
        fullName = try container.decode(String.self, forKey: .fullName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        monthlyIncome = try container.decodeFlexibleDouble(forKey: .monthlyIncome)
        rentAmount = try container.decodeFlexibleDouble(forKey: .rentAmount)
        employmentStatus = try container.decode(EmploymentStatus.self, forKey: .employmentStatus)
        creditScore = try container.decode(Int.self, forKey: .creditScore)
        evictionCount = try container.decode(Int.self, forKey: .evictionCount)
        latePayments = try container.decode(Int.self, forKey: .latePayments)
        criminalRecord = try container.decode(Bool.self, forKey: .criminalRecord)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        riskScore = try container.decode(Int.self, forKey: .riskScore)
        riskLevel = try container.decode(RiskLevel.self, forKey: .riskLevel)
        recommendation = try container.decodeIfPresent(Recommendation.self, forKey: .recommendation) ?? .review
        applicationStatus = try container.decodeIfPresent(ApplicationStatus.self, forKey: .applicationStatus) ?? .pending
        scoreFactors = try container.decodeIfPresent([ScoreFactor].self, forKey: .scoreFactors) ?? []
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

enum RiskLevel: String, Decodable {
    case low
    case medium
    case high

    var title: String {
        rawValue.capitalized
    }
}

enum Recommendation: String, Decodable {
    case approve
    case review
    case reject

    var title: String {
        switch self {
        case .approve:
            return "Approve"
        case .review:
            return "Manual Review"
        case .reject:
            return "Reject"
        }
    }
}

enum ApplicationStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case approved
    case rejected

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

struct ScoreFactor: Decodable, Equatable, Identifiable {
    let label: String
    let impact: Int
    let detail: String

    var id: String {
        "\(label)-\(detail)-\(impact)"
    }
}

enum EmploymentStatus: String, Codable, CaseIterable, Identifiable {
    case employed
    case selfEmployed = "self_employed"
    case student
    case retired
    case unemployed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .employed:
            return "Employed"
        case .selfEmployed:
            return "Self-employed"
        case .student:
            return "Student"
        case .retired:
            return "Retired"
        case .unemployed:
            return "Unemployed"
        }
    }
}

struct TenantPayload: Encodable {
    let fullName: String
    let email: String?
    let phone: String?
    let monthlyIncome: Double
    let rentAmount: Double
    let employmentStatus: EmploymentStatus
    let creditScore: Int
    let evictionCount: Int
    let latePayments: Int
    let criminalRecord: Bool
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case phone
        case monthlyIncome = "monthly_income"
        case rentAmount = "rent_amount"
        case employmentStatus = "employment_status"
        case creditScore = "credit_score"
        case evictionCount = "eviction_count"
        case latePayments = "late_payments"
        case criminalRecord = "criminal_record"
        case notes
    }
}

struct TenantStatusPayload: Encodable {
    let status: ApplicationStatus
    let note: String?
}

struct TenantsResponse: Decodable {
    let tenants: [Tenant]
}

struct TenantResponse: Decodable {
    let tenant: Tenant
}

struct TenantEvent: Decodable, Identifiable {
    let id: Int
    let tenantId: Int
    let actorId: Int
    let actorEmail: String
    let eventType: String
    let message: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case tenantId = "tenant_id"
        case actorId = "actor_id"
        case actorEmail = "actor_email"
        case eventType = "event_type"
        case message
        case createdAt = "created_at"
    }
}

struct TenantEventsResponse: Decodable {
    let events: [TenantEvent]
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }

        let stringValue = try decode(String.self, forKey: key)

        guard let value = Double(stringValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Expected a numeric value."
            )
        }

        return value
    }
}

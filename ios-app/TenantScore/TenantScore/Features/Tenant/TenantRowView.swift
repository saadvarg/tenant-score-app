import SwiftUI

struct TenantRowView: View {
    let tenant: Tenant

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tenant.riskLevel.color.opacity(0.16))

                Text("\(tenant.riskScore)")
                    .font(.headline.bold())
                    .foregroundStyle(tenant.riskLevel.color)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text(tenant.fullName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("\(tenant.employmentStatus.title) · Rent $\(tenant.rentAmount.formattedNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(tenant.riskLevel.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tenant.riskLevel.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tenant.riskLevel.color.opacity(0.12))
                    .clipShape(Capsule())

                Text(tenant.applicationStatus.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tenant.applicationStatus.color)
            }
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension ApplicationStatus {
    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

extension RiskLevel {
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

extension Double {
    var formattedNumber: String {
        formatted(.number.precision(.fractionLength(0)))
    }
}

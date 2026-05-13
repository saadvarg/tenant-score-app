import SwiftUI

struct TenantFormView: View {
    @ObservedObject var viewModel: TenantViewModel
    @Environment(\.dismiss) private var dismiss

    private let tenant: Tenant?

    @State private var fullName: String
    @State private var email: String
    @State private var phone: String
    @State private var monthlyIncome: Double
    @State private var rentAmount: Double
    @State private var employmentStatus: EmploymentStatus
    @State private var creditScore: Int
    @State private var evictionCount: Int
    @State private var latePayments: Int
    @State private var criminalRecord: Bool
    @State private var notes: String
    @State private var isSaving = false
    @State private var localError: String?

    init(viewModel: TenantViewModel, tenant: Tenant? = nil) {
        self.viewModel = viewModel
        self.tenant = tenant
        _fullName = State(initialValue: tenant?.fullName ?? "")
        _email = State(initialValue: tenant?.email ?? "")
        _phone = State(initialValue: tenant?.phone ?? "")
        _monthlyIncome = State(initialValue: tenant?.monthlyIncome ?? 4500)
        _rentAmount = State(initialValue: tenant?.rentAmount ?? 1500)
        _employmentStatus = State(initialValue: tenant?.employmentStatus ?? .employed)
        _creditScore = State(initialValue: tenant?.creditScore ?? 700)
        _evictionCount = State(initialValue: tenant?.evictionCount ?? 0)
        _latePayments = State(initialValue: tenant?.latePayments ?? 0)
        _criminalRecord = State(initialValue: tenant?.criminalRecord ?? false)
        _notes = State(initialValue: tenant?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Applicant") {
                    TextField("Full name", text: $fullName)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Financials") {
                    NumericStepper(title: "Monthly income", value: $monthlyIncome, range: 0...50000, step: 250, prefix: "$")
                    NumericStepper(title: "Rent amount", value: $rentAmount, range: 0...20000, step: 100, prefix: "$")

                    Stepper("Credit score: \(creditScore)", value: $creditScore, in: 300...850, step: 5)

                    Picker("Employment", selection: $employmentStatus) {
                        ForEach(EmploymentStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                }

                Section("Risk History") {
                    Stepper("Evictions: \(evictionCount)", value: $evictionCount, in: 0...10)
                    Stepper("Late payments: \(latePayments)", value: $latePayments, in: 0...24)
                    Toggle("Criminal record", isOn: $criminalRecord)
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let localError {
                    Section {
                        Text(localError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(tenant == nil ? "Add Tenant" : "Edit Tenant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            localError = "Full name is required."
            return
        }

        localError = nil
        isSaving = true

        let payload = TenantPayload(
            fullName: trimmedName,
            email: email.nilIfBlank,
            phone: phone.nilIfBlank,
            monthlyIncome: monthlyIncome,
            rentAmount: rentAmount,
            employmentStatus: employmentStatus,
            creditScore: creditScore,
            evictionCount: evictionCount,
            latePayments: latePayments,
            criminalRecord: criminalRecord,
            notes: notes.nilIfBlank
        )

        let didSave = await viewModel.saveTenant(id: tenant?.id, payload: payload)
        isSaving = false

        if didSave {
            dismiss()
        } else {
            localError = viewModel.errorMessage
        }
    }
}

private struct NumericStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let prefix: String

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(prefix)\(value.formattedNumber)")
                    .fontWeight(.medium)
            }
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

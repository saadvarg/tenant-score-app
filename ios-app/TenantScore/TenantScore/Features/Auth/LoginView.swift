import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TenantScore")
                        .font(.largeTitle.bold())

                    Text(viewModel.isSignupMode ? "Create your landlord account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        await viewModel.submit()
                    }
                } label: {
                    HStack {
                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(viewModel.isSignupMode ? "Create Account" : "Log In")
                                .fontWeight(.semibold)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)

                Button {
                    viewModel.isSignupMode.toggle()
                    viewModel.errorMessage = nil
                } label: {
                    Text(viewModel.isSignupMode ? "Already have an account? Log in" : "New landlord? Create an account")
                        .font(.footnote.weight(.medium))
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

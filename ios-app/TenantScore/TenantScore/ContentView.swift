//
//  ContentView.swift
//  TenantScore
//
//  Created by Saad EL Mouataz on 6/5/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isRestoringSession {
                VStack(spacing: 14) {
                    ProgressView()
                    Text("Loading TenantScore")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if authViewModel.isAuthenticated && authViewModel.user?.role == "admin" {
                AdminDashboardView(authViewModel: authViewModel)
            } else if authViewModel.isAuthenticated {
                TenantDashboardView(authViewModel: authViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .task {
            await authViewModel.restoreSession()
        }
    }
}

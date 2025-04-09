//
//  SubscriptionView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI
import FirebaseAuth

struct SubscriptionView: View {
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SubscriptionViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // MARK: - View Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("Primary"))
                        
                        Text("Tournament Subscription")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Join weekly tournaments and compete for real cash prizes!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Subscription Status Card
                    if let user = authViewModel.user {
                        SubscriptionStatusCard(
                            status: user.subscriptionStatus,
                            expiryDate: user.subscriptionExpiryDate
                        )
                        .padding(.horizontal)
                    }
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(text: "1,000 coins every week", icon: "coins")
                        FeatureRow(text: "Weekly tournament entry", icon: "calendar")
                        FeatureRow(text: "Cash prizes for top 5%", icon: "dollarsign.circle")
                        FeatureRow(text: "Daily login bonuses", icon: "plus.circle")
                        FeatureRow(text: "No ads or interruptions", icon: "hand.thumbsup")
                    }
                    .padding()
                    .background(Color.backgroundSecondary.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Price information
                    Text("Just $20/month")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top)
                    
                    // Subscription Action
                    subscriptionActionButton
                    
                    // Terms text
                    Text("By subscribing, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .padding(.bottom, 30)
            }
            .navigationBarItems(leading: Button("Close") { dismiss() })
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .default) { dismiss() }
            } message: {
                Text(viewModel.successMessage ?? "Operation completed successfully")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .default) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Subscription Action Button
    private var subscriptionActionButton: some View {
        Group {
            if authViewModel.user?.subscriptionStatus == .active {
                VStack(spacing: 12) {
                    // Cancel subscription button
                    Button(action: {
                        Task {
                            await viewModel.cancelSubscription()
                        }
                    }) {
                        Text("Cancel Subscription")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Manage subscription button
                    Button(action: {
                        viewModel.manageSubscription()
                    }) {
                        Text("Manage Subscription")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }
            } else {
                // Subscribe button
                Button(action: {
                    Task {
                        await viewModel.purchaseSubscription()
                    }
                }) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color("Primary"))
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(viewModel.isProcessing)
            }
        }
    }
}

// MARK: - Subscription Status Card
struct SubscriptionStatusCard: View {
    let status: SubscriptionStatus
    let expiryDate: Date?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Status:")
                    .foregroundColor(.secondary)
                Spacer()
                
                Text(statusText)
                    .foregroundColor(statusColor)
                    .fontWeight(.medium)
            }
            
            if let expiryDate = expiryDate {
                HStack {
                    Text("Renews on:")
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Text(expiryDate, style: .date)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    var statusText: String {
        switch status {
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .none: return "Not Subscribed"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .expired: return .orange
        case .cancelled: return .red
        case .none: return .gray
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("Primary"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
        .environmentObject(AuthenticationViewModel())
}

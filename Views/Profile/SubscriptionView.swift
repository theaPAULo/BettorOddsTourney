//
//  SubscriptionView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/8/25.
//


// New file: Views/Profile/SubscriptionView.swift
// Version: 1.0.0
// Created: April 2025

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SubscriptionViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
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
                    
                    // Purchase button
                    if authViewModel.user?.subscriptionStatus == .active {
                        Button(action: {
                            // Handle subscription management
                            viewModel.manageSubscription()
                        }) {
                            Text("Manage Subscription")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.gray)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else {
                        Button(action: {
                            // Handle subscription purchase
                            viewModel.purchaseSubscription()
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
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

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

        // ViewModel for Subscription
        class SubscriptionViewModel: ObservableObject {
            @Published var isProcessing = false
            @Published var showError = false
            @Published var errorMessage: String?
            
            private let db = FirebaseConfig.shared.db
            
            func purchaseSubscription() {
                isProcessing = true
                
                // PLACEHOLDER: This would integrate with StoreKit/IAP
                // For now, simulate a successful purchase with a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.activateSubscription()
                }
            }
            
            func manageSubscription() {
                // This would typically open the App Store subscription management page
                // or an in-app management screen
                
                // For now, just simulate the functionality
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            
            private func activateSubscription() {
                Task {
                    do {
                        guard let userId = Auth.auth().currentUser?.uid else {
                            throw NSError(domain: "", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "User not authenticated"
                            ])
                        }
                        
                        // Set expiry to one month from now
                        let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                        
                        // Update user subscription status
                        try await db.collection("users").document(userId).updateData([
                            "subscriptionStatus": SubscriptionStatus.active.rawValue,
                            "subscriptionExpiryDate": Timestamp(date: expiryDate)
                        ])
                        
                        // Reset weekly coins if needed
                        try await updateWeeklyCoins(userId: userId)
                        
                        // Register for current tournament if needed
                        try await registerForCurrentTournament(userId: userId)
                        
                        await MainActor.run {
                            self.isProcessing = false
                            // Success notification would go here
                        }
                        
                    } catch {
                        await MainActor.run {
                            self.isProcessing = false
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                    }
                }
            }
            
            private func updateWeeklyCoins(userId: String) async throws {
                let userDoc = try await db.collection("users").document(userId).getDocument()
                
                if let currentCoins = userDoc.data()?["weeklyCoins"] as? Int,
                   currentCoins < 1000 {
                    // Reset to 1000 coins for the week
                    try await db.collection("users").document(userId).updateData([
                        "weeklyCoins": 1000,
                        "weeklyCoinsReset": Timestamp(date: Date().nextSunday())
                    ])
                }
            }
            
            private func registerForCurrentTournament(userId: String) async throws {
                // Get current tournament
                let tournamentSnapshot = try await db.collection("tournaments")
                    .whereField("status", isEqualTo: TournamentStatus.active.rawValue)
                    .limit(to: 1)
                    .getDocuments()
                
                guard let tournamentDoc = tournamentSnapshot.documents.first,
                      let tournamentId = tournamentDoc.documentID as String? else {
                    return
                }
                
                // Check if user is already registered
                let leaderboardSnapshot = try await db.collection("leaderboard")
                    .whereField("tournamentId", isEqualTo: tournamentId)
                    .whereField("userId", isEqualTo: userId)
                    .limit(to: 1)
                    .getDocuments()
                
                if leaderboardSnapshot.documents.isEmpty {
                    // Register user for tournament
                    let userDoc = try await db.collection("users").document(userId).getDocument()
                    guard let userData = userDoc.data(),
                          let email = userData["email"] as? String else {
                        throw NSError(domain: "", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "User data not found"
                        ])
                    }
                    
                    // Generate username from email
                    let username = email.components(separatedBy: "@").first ?? "User"
                    
                    // Create leaderboard entry
                    try await db.collection("leaderboard").addDocument(data: [
                        "userId": userId,
                        "tournamentId": tournamentId,
                        "username": username,
                        "rank": 0, // Will be updated by cloud function
                        "coinsRemaining": 1000,
                        "coinsBet": 0,
                        "coinsWon": 0,
                        "betsPlaced": 0,
                        "betsWon": 0,
                        "createdAt": Timestamp(date: Date())
                    ])
                    
                    // Update tournament participant count
                    try await db.collection("tournaments").document(tournamentId).updateData([
                        "participantCount": FieldValue.increment(Int64(1))
                    ])
                    
                    // Update user's current tournament
                    try await db.collection("users").document(userId).updateData([
                        "currentTournamentId": tournamentId
                    ])
                }
            }
        }

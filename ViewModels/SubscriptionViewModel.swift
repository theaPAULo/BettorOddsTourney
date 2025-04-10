//
//  SubscriptionViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  SubscriptionViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccess = false
    @Published var successMessage: String?
    @Published var userSubscription: UserSubscription?
    
    // MARK: - Private Properties
    private let db = FirebaseConfig.shared.db
    private let tournamentService = TournamentService.shared
    
    // MARK: - Initialization
    init() {
        // Load user's subscription data
        Task {
            await loadSubscriptionData()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads current user's subscription data
    func loadSubscriptionData() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard let data = document.data() else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
            }
            
            // Extract subscription data
            let statusString = data["subscriptionStatus"] as? String ?? SubscriptionStatus.none.rawValue
            let status = SubscriptionStatus(rawValue: statusString) ?? .none
            let expiryDate = (data["subscriptionExpiryDate"] as? Timestamp)?.dateValue()
            let startDate = data["subscriptionStartDate"] as? Timestamp
            
            // Create subscription object
            let subscription = UserSubscription(
                userId: userId,
                status: status,
                expiryDate: expiryDate,
                startDate: startDate?.dateValue(),
                lastRenewalDate: (data["lastRenewalDate"] as? Timestamp)?.dateValue(),
                price: 20.0,  // Default price
                nextBillingDate: expiryDate
            )
            
            await MainActor.run {
                self.userSubscription = subscription
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Purchases a new subscription
    func purchaseSubscription() async {
        isProcessing = true
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // PLACEHOLDER: This would integrate with StoreKit/IAP
            // For now, simulate a successful purchase with a direct database update
            
            // Create subscription dates
            let startDate = Date()
            let expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
            
            // Update user subscription status
            let updateData: [String: Any] = [
                "subscriptionStatus": SubscriptionStatus.active.rawValue,
                "subscriptionExpiryDate": Timestamp(date: expiryDate),
                "subscriptionStartDate": Timestamp(date: startDate),
                "lastRenewalDate": Timestamp(date: startDate)
            ]
            
            try await db.collection("users").document(userId).updateData(updateData)
            
            // Register for active tournament if exists
            try await registerForTournament(userId: userId)
            
            // Update local data
            let subscription = UserSubscription(
                userId: userId,
                status: .active,
                expiryDate: expiryDate,
                startDate: startDate,
                lastRenewalDate: startDate,
                price: 20.0,
                nextBillingDate: expiryDate
            )
            
            await MainActor.run {
                self.userSubscription = subscription
                self.successMessage = "Subscription successfully activated"
                self.showSuccess = true
            }
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
    }
    
    /// Cancels existing subscription
    func cancelSubscription() async {
        isProcessing = true
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // PLACEHOLDER: This would integrate with StoreKit/IAP
            // For now, update database directly
            
            try await db.collection("users").document(userId).updateData([
                "subscriptionStatus": SubscriptionStatus.cancelled.rawValue
            ])
            
            // Update local data
            if var subscription = userSubscription {
                subscription.status = .cancelled
                self.userSubscription = subscription
            }
            
            successMessage = "Subscription cancelled. You will have access until the end of your billing period."
            showSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
    }
    
    /// Opens subscription management through App Store
    func manageSubscription() {
        // This would typically open the App Store subscription management page
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    /// Registers user for active tournament
    private func registerForTournament(userId: String) async throws {
        // Find active tournament
        if let tournament = try await tournamentService.fetchActiveTournament() {
            // Register for tournament
            try await tournamentService.registerForTournament(
                userId: userId,
                tournamentId: tournament.id
            )
        }
    }
}

// MARK: - Supporting Types
struct UserSubscription {
    let userId: String
    var status: SubscriptionStatus
    var expiryDate: Date?
    var startDate: Date?
    var lastRenewalDate: Date?
    var price: Double
    var nextBillingDate: Date?
    
    var isActive: Bool {
        return status == .active
    }
    
    var remainingDays: Int {
        guard let expiryDate = expiryDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}
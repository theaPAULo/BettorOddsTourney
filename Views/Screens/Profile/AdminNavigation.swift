//
//  AdminNavigation.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


//
//  AdminNavigation.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//  Version: 1.0.0
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth  // Added this import for Auth


class AdminNavigation: ObservableObject {
    @Published var requiresAuth = false
    @Published var isAuthenticated = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    static let shared = AdminNavigation()
    
    /// Checks if admin features are accessible
    func checkAdminAccess() async {
        guard let user = try? await Auth.auth().currentUser else {
            requiresAuth = false
            return
        }
        
        // Check if user is admin
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(user.uid).getDocument()
            if let userData = doc.data(),
               let adminRole = userData["adminRole"] as? String,
               adminRole == "admin" {
                
                // Check if current session is valid
                if TwoFactorAuth.shared.verifyAdminSession() {
                    isAuthenticated = true
                    requiresAuth = false
                } else {
                    requiresAuth = true
                    isAuthenticated = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Authenticates admin access
    func authenticateAdmin() async {
        do {
            let success = try await TwoFactorAuth.shared.authenticateAdmin()
            if success {
                TwoFactorAuth.shared.updateAdminSession()
                isAuthenticated = true
                requiresAuth = false
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Logs out of admin session
    func logoutAdmin() {
        TwoFactorAuth.shared.clearAdminSession()
        isAuthenticated = false
        requiresAuth = true
    }
}

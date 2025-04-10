//
//  TwoFactorAuth.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//


//
//  TwoFactorAuth.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/29/25.
//  Version: 1.0.0
//

import Foundation
import FirebaseAuth
import LocalAuthentication

class TwoFactorAuth {
    static let shared = TwoFactorAuth()
    private let context = LAContext()
    
    /// Checks if user requires 2FA
    func requires2FA(for user: User) -> Bool {
        return user.adminRole == .admin
    }
    
    /// Authenticates admin user with biometrics
    func authenticateAdmin() async throws -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            throw AuthError.biometricsNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access admin features"
            ) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    /// Verifies admin session is valid
    func verifyAdminSession() -> Bool {
        // Check if last admin authentication was within 30 minutes
        if let lastAuth = UserDefaults.standard.object(forKey: "lastAdminAuth") as? Date {
            return Date().timeIntervalSince(lastAuth) < 1800 // 30 minutes
        }
        return false
    }
    
    /// Updates admin session timestamp
    func updateAdminSession() {
        UserDefaults.standard.set(Date(), forKey: "lastAdminAuth")
    }
    
    /// Clears admin session
    func clearAdminSession() {
        UserDefaults.standard.removeObject(forKey: "lastAdminAuth")
    }
}

enum AuthError: Error {
    case biometricsNotAvailable
    case authenticationFailed
    case sessionExpired
    
    var localizedDescription: String {
        switch self {
        case .biometricsNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed:
            return "Authentication failed"
        case .sessionExpired:
            return "Admin session expired. Please authenticate again"
        }
    }
}
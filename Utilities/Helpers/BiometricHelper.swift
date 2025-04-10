import LocalAuthentication
import SwiftUI

/// Handles all biometric authentication operations in the app
class BiometricHelper {
    // MARK: - Singleton
    static let shared = BiometricHelper()
    private init() {}
    
    // MARK: - Properties
    private let context = LAContext()
    private var error: NSError?
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the device
    var canUseBiometrics: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Returns the type of biometric authentication available
    var biometricType: BiometricType {
        guard canUseBiometrics else { return .none }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    /// Authenticates the user using available biometrics
    /// - Parameter reason: The reason for requesting authentication, shown to the user
    /// - Returns: A boolean indicating success and an optional error message
    func authenticate(reason: String) async -> (success: Bool, error: String?) {
            // Reset context for each new authentication attempt
            context.invalidate()
            
            // Check if biometrics are available
            guard canUseBiometrics else {
                print("⚠️ Biometrics not available - Type: \(context.biometryType.rawValue)")
                var error = LAError(_nsError: NSError(domain: LAErrorDomain, code: LAError.biometryNotAvailable.rawValue))
                return (false, getBiometricErrorMessage(error))
            }
            
            print("🔐 Attempting biometric authentication - Type: \(context.biometryType.rawValue)")
        
        do {
            // Attempt authentication
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return (success, nil)
        } catch let error as LAError {
            // Handle specific biometric errors
            let errorMessage = getBiometricErrorMessage(error)
            return (false, errorMessage)
        } catch {
            // Handle unexpected errors
            return (false, "Authentication failed")
        }
    }
    
    // MARK: - Private Methods
    
    /// Converts LAError to user-friendly error message
    private func getBiometricErrorMessage(_ error: LAError) -> String {
        switch error.code {
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancel:
            return "Authentication was cancelled."
        case .userFallback:
            return "Password authentication selected."
        case .biometryNotAvailable:
            return "Biometric authentication is not available."
        case .biometryNotEnrolled:
            return "No biometric authentication methods are enrolled."
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your device passcode."
        default:
            return "Authentication failed. Please try again."
        }
    }
}

// MARK: - Supporting Types

/// Represents available biometric authentication types
enum BiometricType {
    case none
    case touchID
    case faceID
    
    var description: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .none:
            return "xmark.circle"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        }
    }
}

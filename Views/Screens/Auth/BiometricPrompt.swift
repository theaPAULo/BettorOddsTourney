//
//  BiometricPrompt.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/28/25.
//


//
//  BiometricPrompt.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/27/25.
//  Version: 1.0.0
//

import SwiftUI

struct BiometricPrompt: View {
    // MARK: - Properties
    let title: String
    let subtitle: String
    let onAuthenticate: (Bool) -> Void
    
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(
        title: String = "Authentication Required",
        subtitle: String = "Please authenticate to continue",
        onAuthenticate: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onAuthenticate = onAuthenticate
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Biometric Icon
                Image(systemName: BiometricHelper.shared.biometricType.systemImageName)
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.Brand.primary)
                
                // Title and Subtitle
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(AppTheme.Status.error)
                        .multilineTextAlignment(.center)
                }
                
                // Authenticate Button
                Button(action: authenticate) {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Authenticate with \(BiometricHelper.shared.biometricType.description)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.Brand.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isAuthenticating)
                
                // Cancel Button
                Button("Cancel") {
                    onAuthenticate(false)
                    dismiss()
                }
                .foregroundColor(AppTheme.Text.secondary)
            }
            .padding()
            .onAppear(perform: authenticate)
        }
    }
    
    // MARK: - Methods
    private func authenticate() {
        // Don't proceed if already authenticating
        guard !isAuthenticating else { return }
        
        // Check if biometrics are available
        guard BiometricHelper.shared.canUseBiometrics else {
            errorMessage = "Biometric authentication is not available"
            onAuthenticate(false)
            return
        }
        
        // Start authentication
        isAuthenticating = true
        errorMessage = nil
        
        Task {
            // Provide haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Attempt authentication
            let (success, error) = await BiometricHelper.shared.authenticate(
                reason: "Authenticate to continue"
            )
            
            // Update UI on main thread
            await MainActor.run {
                isAuthenticating = false
                errorMessage = error
                
                if success {
                    onAuthenticate(true)
                    dismiss()
                } else {
                    // Provide error haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
        }
    }
}

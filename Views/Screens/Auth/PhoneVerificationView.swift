// Updated PhoneVerificationView.swift
// Version: 1.2.0 - Modified for tournament system
// Last updated: 2025-04-09

import SwiftUI
import FirebaseAuth

struct PhoneVerificationView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @FocusState private var isPhoneFocused: Bool
    @FocusState private var isCodeFocused: Bool
    @State private var errorMessage: String? = nil
    @State private var isProcessing = false
    
    // MARK: - Phone Formatting
    private func formatPhoneNumber(_ number: String) -> String {
        let cleaned = number.filter { $0.isNumber }
        guard cleaned.count <= 10 else { return phoneNumber }
        
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index == 0 {
                result = "(" + String(char)
            } else if index == 3 {
                result += ") " + String(char)
            } else if index == 6 {
                result += "-" + String(char)
            } else {
                result += String(char)
            }
        }
        return result
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("Primary"))
                        
                        Text(isCodeSent ? "Enter Verification Code" : "Phone Verification")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text(isCodeSent ?
                             "Enter the code we sent to your phone" :
                             "We'll send you a code to verify your phone number")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Phone Input Section
                    if !isCodeSent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("(555) 555-5555", text: $phoneNumber)
                                .keyboardType(.numberPad)
                                .textContentType(.telephoneNumber)
                                .focused($isPhoneFocused)
                                .onChange(of: phoneNumber) { newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Verification Code Section
                    if isCodeSent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verification Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter 6-digit code", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isCodeFocused)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .onChange(of: verificationCode) { newValue in
                                    // Limit to 6 digits
                                    if newValue.count > 6 {
                                        verificationCode = String(newValue.prefix(6))
                                    }
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action Button
                    CustomButton(
                        title: isCodeSent ? "Verify Code" : "Send Code",
                        action: {
                            if isCodeSent {
                                verifyCode()
                            } else {
                                sendVerificationCode()
                            }
                        },
                        isLoading: isProcessing,
                        disabled: isCodeSent ?
                            verificationCode.count != 6 :
                            phoneNumber.filter { $0.isNumber }.count != 10
                    )
                    .padding(.horizontal)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .ignoresSafeArea(.keyboard, edges: .bottom) // Important fix for keyboard constraints
        }
    }
    
    // MARK: - Phone Auth Methods
    
    private func sendVerificationCode() {
        isProcessing = true
        errorMessage = nil
        
        let formattedNumber = "+1" + phoneNumber.filter { $0.isNumber }
        
        // Using Firebase Phone Auth directly
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
            isProcessing = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            // Store verification ID in UserDefaults for the next step
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            
            // Update UI to show verification code input
            withAnimation {
                isCodeSent = true
                isCodeFocused = true
            }
        }
    }
    
    private func verifyCode() {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            errorMessage = "Error retrieving verification data. Please try again."
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            isProcessing = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            
            // Successfully verified and signed in
            UserDefaults.standard.removeObject(forKey: "authVerificationID")
            dismiss()
        }
    }
}

// MARK: - Preview Provider
#Preview {
    PhoneVerificationView()
        .environmentObject(AuthenticationViewModel())
}

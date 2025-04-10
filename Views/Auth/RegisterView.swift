// Updated RegisterView.swift
// Version: 3.0.0 - Modified for tournament system
// Last modified: 2025-04-09

import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isKeyboardVisible = false
    @State private var emailError: String?
    @State private var registrationType: RegistrationType = .email
    @State private var errorMessage: String? // Add this to handle error messages
    
    // MARK: - Enums
    enum RegistrationType {
        case email
        case phone
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        switch registrationType {
        case .email:
            let emailIsValid = EmailValidator.isValid(email)
            let passwordIsValid = password.count >= 8
            let passwordsMatch = password == confirmPassword
            return emailIsValid && passwordIsValid && passwordsMatch && isOver18
        case .phone:
            return phoneNumber.filter { $0.isNumber }.count == 10 && isOver18
        }
    }
    
    // Age verification
    private var isOver18: Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year],
                                                  from: dateOfBirth,
                                                  to: Date())
        return ageComponents.year ?? 0 >= 18
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Sign up to start betting")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 40)
                
                // Registration Type Picker
                Picker("Registration Type", selection: $registrationType) {
                    Text("Email").tag(RegistrationType.email)
                    Text("Phone").tag(RegistrationType.phone)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Form Fields
                VStack(spacing: 16) {
                    if registrationType == .email {
                        // Email Fields
                        emailRegistrationFields
                    } else {
                        // Phone Fields
                        phoneRegistrationFields
                    }
                    
                    // Date of Birth (common for both)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date of Birth")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        DatePicker("", selection: $dateOfBirth,
                                 in: ...Date(),
                                 displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .padding(.horizontal)
                
                if !isOver18 {
                    Text("You must be 18 or older to register")
                        .foregroundColor(.statusError)
                        .font(.caption)
                }
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.statusError)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // Register Button
                Button(action: handleRegistration) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isFormValid ? Color.primary : Color.textSecondary.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(!isFormValid || authViewModel.isLoading)
                
                // Terms and Privacy
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.textSecondary)
                    Button("Sign In") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                .padding(.vertical)
            }
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }
    
    // MARK: - Form Field Views
    private var emailRegistrationFields: some View {
        Group {
            // Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: email) { _ in
                        emailError = EmailValidator.validationMessage(for: email)
                    }
                
                if let error = emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Password Fields
            passwordFields
        }
    }
    
    private var phoneRegistrationFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Phone Number")
                .font(.caption)
                .foregroundColor(.textSecondary)
            TextField("(555) 555-5555", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .onChange(of: phoneNumber) { newValue in
                    phoneNumber = formatPhoneNumber(newValue)
                }
        }
    }
    
    private var passwordFields: some View {
        Group {
            // Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                HStack {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.newPassword)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Confirm Password")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                HStack {
                    if showConfirmPassword {
                        TextField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Confirm your password", text: $confirmPassword)
                            .textContentType(.newPassword)
                    }
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.textSecondary)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
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
    
    private func handleRegistration() {
        guard isFormValid else { return }
        
        Task {
            do {
                switch registrationType {
                case .email:
                    // Email registration - just pass email and password to signUp
                    try await authViewModel.signUp(email: email, password: password)
                    
                case .phone:
                    // Phone registration
                    let formattedNumber = "+1" + phoneNumber.filter { $0.isNumber }
                    
                    // We need a different approach for phone authentication
                    // This is just a placeholder - proper phone auth would need to be implemented
                    errorMessage = "Phone registration not fully implemented yet"
                }
            } catch {
                // Handle errors
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationViewModel())
}

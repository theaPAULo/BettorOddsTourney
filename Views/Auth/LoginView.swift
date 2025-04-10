//
//  LoginView.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Updated by Claude on 4/9/25 - Fixed build errors during tournament transition
//  Version: 2.1.0
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @AppStorage("rememberMe") private var rememberMe = false
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showingForgotPassword = false
    @State private var emailError: String?
    @State private var isKeyboardVisible = false
    @State private var showPhoneVerification = false

    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 8) {
                        Text("BettorOdds")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to continue")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.username)
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
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Remember Me Toggle
                        Toggle("Remember Me", isOn: $rememberMe)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = authViewModel.error?.localizedDescription {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Login Button
                    CustomButton(
                        title: "Sign In",
                        action: handleLogin,
                        style: .primary,
                        isLoading: authViewModel.isLoading,
                        disabled: !isLoginEnabled
                    )
                    .padding(.horizontal, 24)
                    
                    // Phone Sign In Button
                    Button(action: {
                        withAnimation {
                            showPhoneVerification = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Sign in with Phone")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showPhoneVerification) {
                        PhoneVerificationView()
                    }
                    
                    // Forgot Password
                    Button(action: { showingForgotPassword = true }) {
                        Text("Forgot Password?")
                            .foregroundColor(Color("Primary"))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .sheet(isPresented: $showingForgotPassword) {
                        ForgotPasswordView()
                    }
                    
                    Spacer()
                    
                    // Register Link
                    NavigationLink(destination: RegisterView()) {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign Up")
                                .foregroundColor(Color("Primary"))
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 16))
                    }
                    .padding(.bottom, isKeyboardVisible ? 20 : 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupKeyboardNotifications()
            loadSavedEmail()
        }
    }
    
    // MARK: - Computed Properties
    private var isLoginEnabled: Bool {
        !email.isEmpty && !password.isEmpty && EmailValidator.isValid(email) && !authViewModel.isLoading
    }
    
    // MARK: - Methods
    private func handleLogin() {
        guard isLoginEnabled else { return }
        
        // Save email if Remember Me is enabled
        if rememberMe {
            UserDefaults.standard.set(email, forKey: "savedEmail")
        } else {
            UserDefaults.standard.removeObject(forKey: "savedEmail")
        }
        
        // Attempt login - Using Task for async call
        Task {
            try await authViewModel.signIn(
                email: email,
                password: password
            )
        }
    }
    
    private func loadSavedEmail() {
        if rememberMe {
            email = UserDefaults.standard.string(forKey: "savedEmail") ?? ""
        }
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = false
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}

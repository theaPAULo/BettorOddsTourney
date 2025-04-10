// Views/Screens/Auth/LoginView.swift

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    // MARK: - Properties
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isKeyboardVisible = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and Title
                        VStack(spacing: 8) {
                            Image("AppIcon") // Replace with your app logo
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .padding(.top, 60)
                            
                            Text("BettorOdds")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Join weekly tournaments & win real prizes")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 40)
                        
                        // Spacer
                        Spacer(minLength: 40)
                        
                        // Sign-in options
                        VStack(spacing: 20) {
                            // Sign in with Google
                            Button(action: {
                                authViewModel.signInWithGoogle()
                            }) {
                                HStack {
                                    Image("GoogleIcon") // Add this to your asset catalog
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Continue with Google")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Sign in with Apple
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    // Let Apple handle the request creation
                                    // No need to override the request like this
                                },
                                onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        authViewModel.handleAppleSignInCompletion(.success(authorization))
                                    case .failure(let error):
                                        authViewModel.handleAppleSignInCompletion(.failure(error))
                                    }
                                }
                            )
                            .frame(height: 50)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                        
                        // Terms & Privacy
                        VStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Link("Terms of Service", destination: URL(string: "https://yourapp.com/terms")!)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                
                                Text("and")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                
                                Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 24)
                        
                        // 30-Day Free Trial Message
                        Text("Start with a 30-day free trial!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.bottom, isKeyboardVisible ? 20 : 40)
                    }
                    .padding(.horizontal)
                }
                
                // Loading overlay
                if authViewModel.isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: Binding<Bool>(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Sign In Error"),
                    message: Text(authViewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            setupKeyboardNotifications()
        }
    }
    
    // MARK: - Methods
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil, queue: .main
        ) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { _ in
            isKeyboardVisible = false
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthenticationViewModel())
    }
}

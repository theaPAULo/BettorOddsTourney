// ViewModels/AuthenticationViewModel.swift

import SwiftUI
import Firebase
import FirebaseAuth
import AuthenticationServices
import Combine

class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    // MARK: - Private Properties
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    // Add this property under the private properties section
    private let userRepository = UserRepository()
    
    // MARK: - Initialization
    init() {
        // Setup auth state listener
        configureAuthStateListener()
    }
    
    // MARK: - Authentication State
    
    private func configureAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            if let user = user, let userId = user.uid as String? {
                self.isAuthenticated = true
                
                // Launch task to load user data
                Task {
                    do {
                        try await self.loadUser(userId: userId)
                    } catch {
                        print("❌ Error loading user data: \(error.localizedDescription)")
                    }
                }
            } else {
                self.isAuthenticated = false
                self.user = nil
            }
        }
    }
    
    private func loadUser(userId: String) async throws {
        // Since we added @MainActor to the class, we don't need MainActor.run here
        self.isLoading = true
        
        do {
            // Use UserRepository instead of direct Firestore access
            let user = try await userRepository.fetchCurrentUser(userId: userId)
            
            if let user = user {
                self.user = user
                self.isAuthenticated = true
            } else {
                self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user data"])
            }
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
            throw error
        }
    }
    
    // MARK: - Sign In Methods
    
    /// Sign in with Google
    func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Cannot present sign-in UI"
            return
        }
        
        self.isLoading = true
        
        authService.signInWithGoogle(presenting: rootViewController) { [weak self] result in
            guard let self = self else { return }
            
            // Use Task to handle potential async work and update UI on main thread
            Task { @MainActor in
                self.isLoading = false
                
                switch result {
                case .success(let user):
                    self.user = user
                    self.isAuthenticated = true
                case .failure(let error):
                    self.error = error
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Prepares request for Apple Sign-In
    func prepareAppleSignIn() -> ASAuthorizationAppleIDRequest {
        return authService.prepareAppleSignInRequest()
    }
    
    // Add this to the handleAppleSignInCompletion method in AuthenticationViewModel
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        self.isLoading = true
        
        switch result {
        case .success(let authorization):
            authService.handleAppleSignInCompletion(.success(authorization)) { [weak self] result in
                guard let self = self else { return }
                
                Task { @MainActor in
                    self.isLoading = false
                    
                    switch result {
                    case .success(let user):
                        self.user = user
                        self.isAuthenticated = true
                    case .failure(let error):
                        self.error = error
                        self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                        print("🍎 Apple Sign-In error: \(error)")
                    }
                }
            }
            
        case .failure(let error):
            Task { @MainActor in
                self.isLoading = false
                self.error = error
                self.errorMessage = "Apple Sign-In canceled or failed: \(error.localizedDescription)"
                print("🍎 Apple Sign-In error: \(error)")
            }
        }
    }
    
    /// Sign out the current user
    func signOut() throws {
        do {
            try authService.signOut()
            self.user = nil
            isAuthenticated = false
        } catch {
            self.error = error
            throw error
        }
    }
}

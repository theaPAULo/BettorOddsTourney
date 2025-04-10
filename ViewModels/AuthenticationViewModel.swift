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
                
                // Load user data
                Task {
                    try? await self.loadUser(userId: userId)
                }
            } else {
                self.isAuthenticated = false
                self.user = nil
            }
        }
    }
    
    private func loadUser(userId: String) async throws {
        isLoading = true
        
        do {
            // Use UserRepository instead of direct Firestore access
            let user = try await userRepository.fetchCurrentUser(userId: userId)
            
            await MainActor.run {
                if let user = user {
                    self.user = user
                    self.isAuthenticated = true
                } else {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user data"])
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
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
        
        isLoading = true
        
        authService.signInWithGoogle(presenting: rootViewController) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
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
    
    /// Prepare for Apple Sign In
    func prepareAppleSignIn() -> ASAuthorizationAppleIDRequest {
        return authService.prepareAppleSignInRequest()
    }
    
    /// Handle Apple Sign In completion
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        authService.handleAppleSignInCompletion(result) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
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

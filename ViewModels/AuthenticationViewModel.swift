//
//  AuthenticationViewModel.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Shared authentication view model
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isAuthenticated = false
    
    // Shared instance
    static let shared = AuthenticationViewModel()
    
    // MARK: - Private Properties
    private let db = FirebaseConfig.shared.db
    private var userRepository: UserRepository?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    // Changed from private to public for preview access
    init() {
        // Setup auth state listener
        configureAuthStateListener()
        
        // Initialize repository
        do {
            self.userRepository = try UserRepository()
        } catch {
            print("Failed to initialize UserRepository: \(error)")
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Signs in a user with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Load user from database
            if let userId = result.user.uid as String? {
                try await loadUser(userId: userId)
            }
            
            isLoading = false
            isAuthenticated = true
        } catch {
            isLoading = false
            self.error = error
            throw error
        }
    }
    
    /// Creates a new user account
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signUp(email: String, password: String) async throws {
        isLoading = true
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create new user in database
            let newUser = User(
                id: result.user.uid,
                email: email
            )
            
            try await userRepository?.save(newUser)
            
            // Set as current user
            self.user = newUser
            
            isLoading = false
            isAuthenticated = true
        } catch {
            isLoading = false
            self.error = error
            throw error
        }
    }
    
    /// Signs out current user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.user = nil
            isAuthenticated = false
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Configures Firebase auth state listener
    private func configureAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user, let userId = user.uid as String? {
                self?.isAuthenticated = true
                
                // Load user data
                Task {
                    try? await self?.loadUser(userId: userId)
                }
            } else {
                self?.isAuthenticated = false
                self?.user = nil
            }
        }
    }
    
    /// Loads a user from the database
    /// - Parameter userId: The user's ID
    private func loadUser(userId: String) async throws {
        guard let userRepository = userRepository else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User repository not initialized"])
        }
        
        // Fetch user from database
        if let user = try await userRepository.fetch(id: userId) {
            await MainActor.run {
                self.user = user
                self.isAuthenticated = true
            }
        } else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
    }
}

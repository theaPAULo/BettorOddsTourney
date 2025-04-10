//
//  AuthenticationService.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/10/25.
//  Version: 1.0.1 - Fixed Google Sign-In implementation


// Services/AuthenticationService.swift

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

/// Service to handle authentication with Google and Apple
class AuthenticationService {
    // MARK: - Singleton
    static let shared = AuthenticationService()
    
    // MARK: - Properties
    private let auth = Auth.auth()
    private let db = FirebaseConfig.shared.db
    private var currentNonce: String? // Used for Apple Sign-In
    
    // MARK: - Google Sign In
    
    /// Signs in with Google
    /// - Parameters:
    ///   - viewController: The view controller to present the sign-in interface
    ///   - completion: Completion handler with Result containing User or Error
    func signInWithGoogle(presenting viewController: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "Authentication", code: 0, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration missing client ID"])
            completion(.failure(error))
            return
        }
        
        // Create Google Sign In configuration
        let config = GIDConfiguration(clientID: clientID)
        
        // Start Google Sign In flow - Updated for latest Google Sign In SDK
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                let error = NSError(domain: "Authentication", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign in result is nil"])
                completion(.failure(error))
                return
            }
            
            guard let idToken = result.user.idToken?.tokenString else {
                let error = NSError(domain: "Authentication", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"])
                completion(.failure(error))
                return
            }
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            // Get email from Google user if available
            let email = result.user.profile?.email
            
            // Sign in with Firebase
            self.handleFirebaseSignIn(
                with: credential,
                provider: .google,
                email: email,
                completion: completion
            )
        }
    }
    
    // MARK: - Apple Sign In
    
    /// Generates a random nonce for Apple Sign In
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    /// Creates SHA256 hash of the input string
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    /// Prepares request for Apple Sign In
    func prepareAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        return request
    }
    
    /// Handles Apple Sign In completion
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>, completion: @escaping (Result<User, Error>) -> Void) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                let error = NSError(domain: "Authentication", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple Sign In credentials"])
                completion(.failure(error))
                return
            }
            
            // Create Firebase credential
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            // Get display name from Apple credential if available
            var displayName: String? = nil
            if let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                if !firstName.isEmpty || !lastName.isEmpty {
                    displayName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
                }
            }
            
            // Sign in with Firebase, passing along display name and email from Apple if available
            self.handleFirebaseSignIn(
                with: credential,
                provider: .apple,
                displayName: displayName,
                email: appleIDCredential.email,
                completion: completion
            )
            
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    // MARK: - Firebase Authentication
    
    /// Handles sign in with Firebase using the provided credential
    private func handleFirebaseSignIn(
        with credential: AuthCredential,
        provider: User.AuthProvider,
        displayName: String? = nil,
        email: String? = nil,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        auth.signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                let error = NSError(domain: "Authentication", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get Firebase user"])
                completion(.failure(error))
                return
            }
            
            // Check if user exists in Firestore
            self.db.collection("users").document(firebaseUser.uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let isNewUser = snapshot?.exists == false
                
                // Replace the part where a new user is created with this:
                if isNewUser {
                    // Create new user for Firestore
                    var user = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? email ?? ""
                    )
                    
                    // Set auth provider based on the credential provider
                    if credential.provider == "google.com" {
                        user.authProvider = .google
                    } else if credential.provider == "apple.com" {
                        user.authProvider = .apple
                    }
                    
                    // Set up trial period (30 days from now)
                    user.subscriptionStatus = .active
                    let now = Date()
                    user.lastLoginDate = now
                    let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now)
                    user.subscriptionExpiryDate = thirtyDaysLater
                    
                    // Save new user to Firestore
                    do {
                        let userData = user.toDictionary()
                        try self.db.collection("users").document(user.id).setData(userData)
                        
                        // Initialize user's first batch of coins
                        try await UserService.shared.resetWeeklyCoins(for: user.id)
                        
                        completion(.success(user))
                    } catch {
                        completion(.failure(error))
                    }
                }
                else {
                    // User exists, fetch their data
                    if let snapshot = snapshot, let user = User(document: snapshot) {
                        // Update last login date
                        let userRef = self.db.collection("users").document(user.id)
                        userRef.updateData([
                            "lastLoginDate": Timestamp(date: Date())
                        ])
                        
                        // Process login streak if needed
                        self.processLoginStreak(for: user)
                        
                        completion(.success(user))
                    } else {
                        let error = NSError(domain: "Authentication", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse user data"])
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Processes login streak for returning users
    private func processLoginStreak(for user: User) {
        guard let lastLoginDate = user.lastLoginDate else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Check if the last login was yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now) {
            let lastLoginDay = calendar.startOfDay(for: lastLoginDate)
            let yesterdayDay = calendar.startOfDay(for: yesterday)
            
            if calendar.isDate(lastLoginDay, inSameDayAs: yesterdayDay) {
                // Last login was yesterday, increment streak
                self.db.collection("users").document(user.id).updateData([
                    "loginStreak": user.loginStreak + 1
                ])
            } else if !calendar.isDateInToday(lastLoginDay) {
                // Last login was not yesterday and not today, reset streak
                self.db.collection("users").document(user.id).updateData([
                    "loginStreak": 1
                ])
            }
        }
    }
    
    // MARK: - Sign Out
    
    /// Signs out the current user
    func signOut() throws {
        try auth.signOut()
    }
}

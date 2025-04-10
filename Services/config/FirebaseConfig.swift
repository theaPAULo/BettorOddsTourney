// Services/config/FirebaseConfig.swift

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

/// Manages Firebase configuration and initialization
class FirebaseConfig {
    // MARK: - Singleton
    static let shared = FirebaseConfig()
    
    // MARK: - Properties
    let db: Firestore
    let auth: Auth
    let storage: Storage
    
    // MARK: - Initialization
    private init() {
        // Do NOT configure Firebase here anymore - the AppDelegate will do it
        // We just need to check if it's configured
        if FirebaseApp.app() == nil {
            print("⚠️ Warning: Firebase is not configured. This should be done in AppDelegate.")
            // Configure as a fallback only
            FirebaseApp.configure()
            print("✅ Firebase app configured (fallback)")
        } else {
            print("✅ Firebase already configured, using existing app")
        }
        
        // Initialize Firebase services
        self.db = Firestore.firestore()
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true // Enable offline persistence
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited // Unlimited cache size
        self.db.settings = settings
        
        print("✅ Firebase services initialized")
        configureDebugSettings()
    }
    
    // MARK: - Collection References
    
    /// Returns a reference to the users collection
    var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    /// Returns a reference to the bets collection
    var betsCollection: CollectionReference {
        return db.collection("bets")
    }
    
    /// Returns a reference to the transactions collection
    var transactionsCollection: CollectionReference {
        return db.collection("transactions")
    }
    
    /// Returns a reference to the games collection
    var gamesCollection: CollectionReference {
        return db.collection("games")
    }
    
    /// Returns a reference to the settings collection
    var settingsCollection: CollectionReference {
        return db.collection("settings")
    }
    
    // MARK: - Debug Configuration
    private func configureDebugSettings() {
        #if DEBUG
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false
        db.settings = settings
        print("🔧 Debug settings configured for Firestore")
        #endif
    }
}

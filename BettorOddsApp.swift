// BettorOddsApp.swift

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck // Add this import
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize Firebase configuration FIRST
        FirebaseApp.configure()
        print("✅ Firebase App configured directly")
        
        // THEN initialize the shared config
        _ = FirebaseConfig.shared
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Configure Firebase AppCheck - simpler approach without debug provider
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("✅ Firebase AppCheck configured")
        
        // Request notification permissions
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions) { granted, error in
                if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("✅ Notification permission granted: \(granted)")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        
        Task {
            do {
                try await DataInitializationService.shared.initializeSettings()
                print("✅ App settings initialized")
            } catch {
                print("❌ Failed to initialize app settings: \(error)")
            }
        }
        return true
    }
    
    // Rest of your AppDelegate methods stay the same
}

@main
struct BettorOddsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var showLaunch = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                
                if showLaunch {
                    LaunchScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showLaunch = false
                    }
                }
            }
        }
    }
}

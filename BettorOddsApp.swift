// BettorOddsApp.swift

import SwiftUI
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Initialize Firebase configuration
        _ = FirebaseConfig.shared
        
        // Add this right after Firebase initialization in your AppDelegate
        TestService.shared.testFirebaseConnection { success, message in
            if success {
                print("✅ \(message)")
            } else {
                print("❌ \(message)")
            }
        }
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
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
        
        // Add this to your AppDelegate class at the end of the application(_:didFinishLaunchingWithOptions:) method
        // Just before the return true statement:

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
    
    // Handle URL schemes
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if Auth.auth().canHandle(url) {
            return true
        }
        return false
    }
    
    // Handle remote notifications - IMPORTANT for Firebase Phone Auth
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Received remote notification")
        
        // Forward the notification to Firebase Auth
        if Auth.auth().canHandleNotification(userInfo) {
            print("✅ Firebase can handle notification")
            completionHandler(.noData)
            return
        }
        
        print("❌ Firebase cannot handle notification")
        completionHandler(.newData)
    }
    
    // Handle APNs token
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 Received APNs token")
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    }
    
    // Handle APNs registration errors
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // UNUserNotificationCenterDelegate methods
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
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

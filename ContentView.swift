//
//  ContentView.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Modified for tournament system
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject private var authViewModel = AuthenticationViewModel.shared
    
    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                // User is logged in - show main app content
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                // User is not logged in - show welcome/login screen
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            setupAppearance()
        }
    }
    
    /// Sets up the global app appearance
    private func setupAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textPrimary)
        ]
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
        tabBarAppearance.unselectedItemTintColor = UIColor(Color.textSecondary.opacity(0.5))
        
        // Set the status bar style
        if #available(iOS 15.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Color.backgroundPrimary)
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

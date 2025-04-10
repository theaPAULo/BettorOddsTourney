//
//  MainTabView.swift
//  BettorOdds
//
//  Updated by Paul Soni on 4/9/25
//  Version: 3.0.0 - Added tournament support
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    @State private var showSubscriptionPrompt = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Games Tab
            NavigationView {
                GamesView()
            }
            .tabItem {
                Label("Games", systemImage: "sportscourt.fill")
            }
            .tag(0)
            
            // My Bets Tab
            NavigationView {
                MyBetsView()
            }
            .tabItem {
                Label("My Bets", systemImage: "list.bullet.clipboard")
            }
            .tag(1)
            
            // NEW: Leaderboard Tab
            NavigationView {
                LeaderboardView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Leaderboard", systemImage: "trophy.fill")
            }
            .tag(2)
            
            // Profile Tab (moved to tab 3)
            NavigationView {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
            
            // Admin Tab (only shown for admin users)
            if authViewModel.user?.adminRole == .admin {
                NavigationView {
                    AdminDashboardView()
                        .onAppear {
                            Task {
                                await adminNav.checkAdminAccess()
                            }
                        }
                }
                .tabItem {
                    Label("Admin", systemImage: "shield.fill")
                }
                .tag(4)
            }
        }
        .accentColor(Color("Primary")) // Tab bar tint color
        .sheet(isPresented: $adminNav.requiresAuth) {
            AdminAuthView()
        }
        .sheet(isPresented: $showSubscriptionPrompt) {
            SubscriptionView()
                .environmentObject(authViewModel)
        }
        .alert("Error", isPresented: $adminNav.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(adminNav.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Check subscription status
            if let user = authViewModel.user,
               user.subscriptionStatus == .none {
                // Show subscription prompt after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSubscriptionPrompt = true
                }
            }
            
            // Add haptic feedback for tab selection
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
        }
        .onChange(of: selectedTab) { _ in
            // Provide haptic feedback on tab change
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

/// Admin Authentication View
struct AdminAuthView: View {
    @EnvironmentObject var adminNav: AdminNavigation
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 70))
                .foregroundColor(Color("Primary"))
            
            Text("Admin Authentication")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Biometric authentication is required to access admin functions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await adminNav.authenticateAdmin()
                }
            }) {
                Text("Authenticate Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Primary"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Button(action: {
                adminNav.requiresAuth = false
            }) {
                Text("Cancel")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

// MARK: - Preview Provider
#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}

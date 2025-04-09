// Updated MainTabView.swift
// Version: 3.0.0 - Added tournament support
// Updated: April 2025

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var adminNav = AdminNavigation.shared
    @State private var selectedTab = 0
    
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
            }
            .tabItem {
                Label("Leaderboard", systemImage: "trophy.fill")
            }
            .tag(2)
            
            // Profile Tab (moved to tab 3)
            NavigationView {
                ProfileView()
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
        .accentColor(AppTheme.Brand.primary) // Tab bar tint color
        .sheet(isPresented: $adminNav.requiresAuth) {
            AdminAuthView()
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

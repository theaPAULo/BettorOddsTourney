//
//  WelcomeView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  WelcomeView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("Primary").opacity(0.8),
                        Color("Primary").opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 40) {
                    // Logo and title
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("BettorOdds")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Tournament Betting")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(icon: "trophy.fill", text: "Weekly Tournaments")
                        FeatureRow(icon: "dollarsign.circle.fill", text: "Real Cash Prizes")
                        FeatureRow(icon: "person.3.fill", text: "Compete With Friends")
                        FeatureRow(icon: "chart.bar.fill", text: "Track Your Progress")
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(Color("Primary"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showSignUp = true
                        }) {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
                
                // Navigation links
                NavigationLink(destination: LoginView(), isActive: $showLogin) { EmptyView() }
                NavigationLink(destination: RegisterView(), isActive: $showSignUp) { EmptyView() }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// Placeholder views for navigation
struct LoginView: View {
    var body: some View {
        Text("Login View")
            .navigationTitle("Log In")
    }
}

struct RegisterView: View {
    var body: some View {
        Text("Register View")
            .navigationTitle("Create Account")
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationViewModel.shared)
}
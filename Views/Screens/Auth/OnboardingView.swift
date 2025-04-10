//
//  OnboardingView.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/10/25.
//


// Views/Screens/Auth/OnboardingView.swift
// (Replace RegisterView with this)

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                Text("Welcome to BettorOdds")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 40)
                
                // Features list
                VStack(alignment: .leading, spacing: 20) {
                    featureRow(
                        icon: "trophy.fill",
                        title: "Weekly Tournaments",
                        description: "Compete against others for real cash prizes"
                    )
                    
                    featureRow(
                        icon: "dollarsign.circle.fill",
                        title: "1000 Free Coins",
                        description: "Get 1000 tournament coins weekly to place bets"
                    )
                    
                    featureRow(
                        icon: "calendar.badge.clock",
                        title: "30-Day Free Trial",
                        description: "Try all premium features free for 30 days"
                    )
                    
                    featureRow(
                        icon: "lock.shield.fill",
                        title: "Secure Authentication",
                        description: "Sign in easily with Google or Apple"
                    )
                }
                .padding()
                
                // Subscription info
                VStack(spacing: 8) {
                    Text("After your trial")
                        .font(.headline)
                    
                    Text("$20/month")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Cancel anytime during your trial")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Back to sign in
                Button(action: {
                    dismiss()
                }) {
                    Text("Back to Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 30)
            }
            .padding(.bottom, 50)
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
//
//  CoinPurchaseView.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/26/25.
//  Version: 2.0.0

import SwiftUI

struct CoinPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedAmount: Int?
    @State private var isProcessing = false
    
    let purchaseAmounts = [10, 25, 50, 100, 250, 500]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Info Section
                    VStack(spacing: 8) {
                        Text("Purchase Coins")
                            .font(.system(size: 24, weight: .bold))
                        Text("1 green coin = $1 USD")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Text.secondary)
                    }
                    .padding(.top)
                    
                    // Amount Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(purchaseAmounts, id: \.self) { amount in
                            PurchaseAmountCard(
                                amount: amount,
                                isSelected: selectedAmount == amount,
                                action: { selectedAmount = amount }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Purchase Button
                    CustomButton(
                        title: isProcessing ? "Processing..." : "Purchase Now",
                        action: handlePurchase,
                        isLoading: isProcessing,
                        disabled: selectedAmount == nil || isProcessing
                    )
                    .padding(.horizontal)
                    
                    // Terms
                    Text("By purchasing coins, you agree to our Terms of Service")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handlePurchase() {
        guard let amount = selectedAmount else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        isProcessing = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            showPurchaseConfirmation(amount: amount)
        }
    }
    
    private func showPurchaseConfirmation(amount: Int) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Purchase Successful",
            message: "You have successfully purchased \(amount) green coins.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            dismiss()
        })
        
        viewController.present(alert, animated: true)
    }
}

struct PurchaseAmountCard: View {
    let amount: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var cardBackground: some View {
        if isSelected {
            return LinearGradient(
                colors: [.primary, .primary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(uiColor: .systemBackground), Color(uiColor: .systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Coin Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green.opacity(0.2), .green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Text("💚")
                        .font(.system(size: 24))
                }
                
                // Amount
                Text("\(amount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Price
                Text("$\(amount)")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary : Color.secondary.opacity(0.1),
                           lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isSelected ? Color.primary.opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    CoinPurchaseView()
}

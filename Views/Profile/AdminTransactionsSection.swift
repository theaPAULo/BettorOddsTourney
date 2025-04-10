//
//  AdminTransactionsSection.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  AdminTransactionsSection.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation for tournament system
//

import SwiftUI
import FirebaseFirestore

struct AdminTransactionsSection: View {
    @StateObject private var viewModel = AdminTransactionsViewModel()
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscriptions & Transactions")
                .font(.title2)
                .fontWeight(.bold)
            
            // Filter controls
            HStack {
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        Image(systemName: "calendar")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Picker("Type", selection: $viewModel.filterType) {
                    Text("All").tag(nil as TransactionType?)
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as TransactionType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
            }
            
            // Stats overview
            HStack {
                AdminStatBox(
                    title: "Total Transactions",
                    value: "\(viewModel.stats.totalTransactions)"
                )
                
                AdminStatBox(
                    title: "New Subscribers",
                    value: "\(viewModel.stats.newSubscriptions)"
                )
                
                AdminStatBox(
                    title: "Revenue",
                    value: "$\(viewModel.stats.revenue)"
                )
            }
            
            // Transactions list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.transactions.isEmpty {
                Text("No transactions match the selected filters")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                transactionsListView
            }
            
            // Refresh button
            Button(action: {
                Task {
                    await viewModel.loadTransactions(date: selectedDate)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showingDatePicker) {
            datePicker
        }
        .onAppear {
            Task {
                await viewModel.loadTransactions(date: selectedDate)
            }
        }
    }
    
    private var transactionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .frame(maxHeight: 300)
    }
    
    private var datePicker: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Apply") {
                    showingDatePicker = false
                    Task {
                        await viewModel.loadTransactions(date: selectedDate)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarItems(trailing: Button("Cancel") {
                showingDatePicker = false
            })
        }
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.displayName)
                    .font(.system(size: 16, weight: .medium))
                
                Text("User ID: \(transaction.userId)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(transaction.type == .subscription ? .green : .primary)
                
                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}

// MARK: - View Model
class AdminTransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var stats = TransactionStats()
    @Published var filterType: TransactionType? = nil
    
    private let db = FirebaseConfig.shared.db
    private let transactionRepository = try? TransactionRepository()
    
    struct TransactionStats {
        var totalTransactions: Int = 0
        var newSubscriptions: Int = 0
        var revenue: Int = 0
    }
    
    @MainActor
    func loadTransactions(date: Date) async {
        isLoading = true
        
        // The real implementation would interact with Firestore to get transactions
        // For now, simulate with sample data
        
        // Create sample transactions
        var sampleTransactions: [Transaction] = []
        
        // Subscription transactions
        sampleTransactions.append(
            Transaction(
                id: "trans1",
                userId: "user1",
                amount: 19.99,
                type: .subscription,
                timestamp: Date().addingTimeInterval(-3600),
                notes: "Monthly subscription"
            )
        )
        
        sampleTransactions.append(
            Transaction(
                id: "trans2",
                userId: "user2",
                amount: 19.99,
                type: .subscription,
                timestamp: Date().addingTimeInterval(-7200),
                notes: "Monthly subscription"
            )
        )
        
        // Tournament prize transaction
        sampleTransactions.append(
            Transaction(
                id: "trans3",
                userId: "user3",
                amount: 100.00,
                type: .tournamentPrize,
                timestamp: Date().addingTimeInterval(-10800),
                notes: "1st place in weekly tournament"
            )
        )
        
        // Filter by type if needed
        if let filterType = filterType {
            sampleTransactions = sampleTransactions.filter { $0.type == filterType }
        }
        
        // Calculate stats
        let totalTransactions = sampleTransactions.count
        let newSubscriptions = sampleTransactions.filter { $0.type == .subscription }.count
        let revenue = sampleTransactions
            .filter { $0.type == .subscription || $0.type == .coinPurchase }
            .reduce(0) { $0 + Int($1.amount) }
        
        // Update UI
        await MainActor.run {
            self.transactions = sampleTransactions
            self.stats = TransactionStats(
                totalTransactions: totalTransactions,
                newSubscriptions: newSubscriptions,
                revenue: revenue
            )
            self.isLoading = false
        }
    }
}

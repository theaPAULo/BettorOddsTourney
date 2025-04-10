//
//  AdminBetsSection.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25.
//


//
//  AdminBetsSection.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation for tournament system
//

import SwiftUI
import FirebaseFirestore

struct AdminBetsSection: View {
    @StateObject private var viewModel = AdminBetsViewModel()
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Bets")
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
                
                Picker("Status", selection: $viewModel.filterStatus) {
                    Text("All").tag(nil as BetStatus?)
                    ForEach(BetStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status as BetStatus?)
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
                    title: "Total Bets",
                    value: "\(viewModel.stats.totalBets)"
                )
                
                AdminStatBox(
                    title: "Tournament Coins",
                    value: "\(viewModel.stats.totalCoins)"
                )
                
                AdminStatBox(
                    title: "Win Rate",
                    value: "\(viewModel.stats.winPercentage)%"
                )
            }
            
            // Bets list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.bets.isEmpty {
                Text("No bets match the selected filters")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                betsListView
            }
            
            // Refresh button
            Button(action: {
                Task {
                    await viewModel.loadBets(date: selectedDate)
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
            datePickerView
        }
        .onAppear {
            Task {
                await viewModel.loadBets(date: selectedDate)
            }
        }
    }
    
    private var betsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.bets) { bet in
                    AdminBetRow(bet: bet)
                }
            }
        }
        .frame(maxHeight: 300)
    }
    
    private var datePickerView: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Button("Apply") {
                    showingDatePicker = false
                    Task {
                        await viewModel.loadBets(date: selectedDate)
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

struct AdminBetRow: View {
    let bet: Bet
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bet.team)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Spread: \(String(format: "%.1f", bet.initialSpread))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(bet.amount) coins")
                    .font(.system(size: 16, weight: .medium))
                
                StatusBadge(status: bet.status)
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}

// MARK: - View Model
class AdminBetsViewModel: ObservableObject {
    @Published var bets: [Bet] = []
    @Published var isLoading = false
    @Published var stats = BetStats()
    @Published var filterStatus: BetStatus? = nil
    
    private let db = FirebaseConfig.shared.db
    
    struct BetStats {
        var totalBets: Int = 0
        var totalCoins: Int = 0
        var winPercentage: Int = 0
    }
    
    @MainActor
    func loadBets(date: Date) async {
        isLoading = true
        
        do {
            // Calculate date range
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // Create query
            var query: Query = db.collection("bets")
                .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("createdAt", isLessThan: Timestamp(date: endOfDay))
            
            // Add status filter if applicable
            if let status = filterStatus {
                query = query.whereField("status", isEqualTo: status.rawValue)
            }
            
            // Execute query
            let snapshot = try await query.getDocuments()
            
            // Process results
            let fetchedBets = snapshot.documents.compactMap { Bet(document: $0) }
            
            // Calculate stats
            let totalBets = fetchedBets.count
            let totalCoins = fetchedBets.reduce(0) { $0 + $1.amount }
            let wonBets = fetchedBets.filter { $0.status == .won }.count
            let winPercentage = totalBets > 0 ? (wonBets * 100) / totalBets : 0
            
            // Update UI
            await MainActor.run {
                self.bets = fetchedBets
                self.stats = BetStats(
                    totalBets: totalBets,
                    totalCoins: totalCoins,
                    winPercentage: winPercentage
                )
                self.isLoading = false
            }
        } catch {
            print("Error loading bets: \(error.localizedDescription)")
            self.isLoading = false
        }
    }
}
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    // App Settings
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    // Security Settings
    @State private var requireBiometrics = true
    @State private var showingBiometricPrompt = false
    @State private var showingDisableBiometricsAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Appearance Section
                Section {
                    HStack {
                        Label("Dark Mode", systemImage: "moon.fill")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: $isDarkMode)
                            .tint(.primary)
                    }
                } header: {
                    Text("Appearance")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Changes app theme between light and dark mode")
                        .foregroundColor(.textSecondary)
                }
                
                // Security Section
                if BiometricHelper.shared.canUseBiometrics {
                    Section {
                        HStack {
                            Label(
                                "Require \(BiometricHelper.shared.biometricType.description)",
                                systemImage: BiometricHelper.shared.biometricType.systemImageName
                            )
                            .foregroundColor(.textPrimary)
                            Spacer()
                            Toggle("", isOn: $requireBiometrics)
                                .tint(.primary)
                        }
                    } header: {
                        Text("Security")
                            .foregroundColor(.textSecondary)
                    } footer: {
                        Text("When enabled, biometric authentication will be required for all real money transactions.")
                            .foregroundColor(.textSecondary)
                    }
                    .onChange(of: requireBiometrics) { newValue in
                        handleBiometricToggle(isEnabled: newValue)
                    }
                }
                
                // Notifications Section
                Section {
                    HStack {
                        Label("Enable Notifications", systemImage: "bell.fill")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(.primary)
                    }
                } header: {
                    Text("Notifications")
                        .foregroundColor(.textSecondary)
                } footer: {
                    Text("Receive updates about your bets and important events")
                        .foregroundColor(.textSecondary)
                }
                
                // App Info Section
                Section {
                    InfoRow(title: "Version", value: "1.0.0")
                    InfoRow(
                        title: "Biometric Status",
                        value: BiometricHelper.shared.biometricType.description
                    )
                    Button(action: {
                        // Open privacy policy
                    }) {
                        Label("Privacy Policy", systemImage: "doc.text.fill")
                            .foregroundColor(.textPrimary)
                    }
                    Button(action: {
                        // Open terms of service
                    }) {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                            .foregroundColor(.textPrimary)
                    }
                } header: {
                    Text("About")
                        .foregroundColor(.textSecondary)
                }
                
                // Danger Zone
                Section {
                    Button(action: {
                        // Clear app data
                    }) {
                        Label("Clear App Data", systemImage: "trash.fill")
                            .foregroundColor(.statusError)
                    }
                    Button(action: {
                        authViewModel.signOut()
                        dismiss()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.statusError)
                    }
                } header: {
                    Text("Danger Zone")
                        .foregroundColor(.statusError)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.backgroundPrimary)
            .scrollContentBackground(.hidden)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showingBiometricPrompt) {
                BiometricPrompt(
                    title: "Confirm Settings Change",
                    subtitle: "Authenticate to change security settings"
                ) { success in
                    if success {
                        if let user = authViewModel.user {
                            Task {
                                await updateUserPreferences(for: user)
                            }
                        }
                    } else {
                        requireBiometrics = !requireBiometrics
                    }
                }
            }
            .alert("Disable Biometric Authentication?", isPresented: $showingDisableBiometricsAlert) {
                Button("Cancel", role: .cancel) {
                    requireBiometrics = true
                }
                Button("Disable", role: .destructive) {
                    showingBiometricPrompt = true
                }
            } message: {
                Text("Disabling biometric authentication will reduce the security of your real money transactions. Are you sure you want to continue?")
            }
        }
    }
    
    private func handleBiometricToggle(isEnabled: Bool) {
        if !isEnabled {
            showingDisableBiometricsAlert = true
        } else {
            showingBiometricPrompt = true
        }
    }
    
    private func updateUserPreferences(for user: User) async {
        do {
            let newPreferences = UserPreferences(
                useBiometrics: requireBiometrics,
                darkMode: isDarkMode,
                notificationsEnabled: notificationsEnabled,
                requireBiometricsForGreenCoins: requireBiometrics
            )
            
            var updatedUser = user
            updatedUser.preferences = newPreferences
            
            try await authViewModel.updateUser(updatedUser)
            
            await MainActor.run {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                requireBiometrics = !requireBiometrics
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthenticationViewModel())
}

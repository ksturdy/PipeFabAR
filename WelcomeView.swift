//
//  WelcomeView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-31.
//

import SwiftUI
import AuthenticationServices

/// Welcome screen shown when the app first launches
struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var navigateToProjects = false
    @State private var isRestoring = false
    @State private var restoreMessage: String?
    @State private var signInError: String?

    // Get app version from bundle
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildDate: String {
        // Format today's date
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // App Logo
                    VStack(spacing: 20) {
                        BrandingView(size: 120)

                        Text("by Mission Integrated Systems")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Get Started Button
                    Button(action: {
                        navigateToProjects = true
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }

                    // Sign In with Apple
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: { result in
                        handleAppleSignIn(result)
                    })
                    .signInWithAppleButtonStyle(.white)
                    .frame(maxWidth: 300, maxHeight: 50)
                    .cornerRadius(12)

                    // Feedback Button
                    Button(action: sendFeedback) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Send Feedback")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 8)

                    #if DEBUG
                    Button("Skip (Debug) — Unlock Pro") {
                        subscriptionManager.debugUnlock()
                        navigateToProjects = true
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    #endif

                    // Restore Purchases
                    Button {
                        Task {
                            isRestoring = true
                            await subscriptionManager.restore()
                            isRestoring = false
                            if subscriptionManager.isProSubscriber {
                                restoreMessage = "Your Pro subscription has been restored."
                            } else {
                                restoreMessage = "No active subscription found."
                            }
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(height: 20)
                        } else {
                            Text("Restore Purchases")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(isRestoring)

                    Spacer()

                    // Disclaimer
                    Text("PipeFabAR is provided for reference purposes only. Mission Integrated Systems is not responsible for errors in dimensions, specifications, or fabrication results. Always verify measurements and consult qualified professionals before fabrication.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Legal Links
                    HStack(spacing: 12) {
                        Link("Privacy Policy",
                             destination: URL(string: "https://www.missionintegratedsystems.com/privacy")!)
                        Text("·").foregroundColor(.secondary)
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)

                    // Version Info
                    VStack(spacing: 4) {
                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(buildDate)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToProjects) {
                ProjectListView()
            }
        }
        .onAppear { print("⏱ WelcomeView appeared \(Date())") }
        .task {
            SpecificationManager.shared.ensureDefaultSpecifications(in: modelContext)
        }
        .alert("Restore Purchases", isPresented: Binding(
            get: { restoreMessage != nil },
            set: { if !$0 { restoreMessage = nil } }
        )) {
            Button("OK") { restoreMessage = nil }
        } message: {
            Text(restoreMessage ?? "")
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )) {
            Button("OK") { subscriptionManager.errorMessage = nil }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
        .alert("Sign In Error", isPresented: Binding(
            get: { signInError != nil },
            set: { if !$0 { signInError = nil } }
        )) {
            Button("OK") { signInError = nil }
        } message: {
            Text(signInError ?? "")
        }
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let auth) = result,
              let credential = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            if case .failure(let error) = result {
                signInError = error.localizedDescription
            }
            return
        }
        let nameParts = [credential.fullName?.givenName, credential.fullName?.familyName]
        let fullName = nameParts.compactMap { $0 }.joined(separator: " ")
        Task {
            do {
                try await BackendService.shared.signInWithApple(
                    identityToken: token,
                    fullName: fullName.isEmpty ? nil : fullName
                )
                await subscriptionManager.refreshPromoStatus()
            } catch {
                signInError = error.localizedDescription
            }
        }
    }

    func sendFeedback() {
        let email = "sales@missionintegratedsystems.com"
        let subject = "PipeFab AR Feedback"
        let body = "Version: \(appVersion)\nDate: \(buildDate)\n\nFeedback:\n"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    WelcomeView()
        .modelContainer(DataController.shared.container)
        .environmentObject(SubscriptionManager())
}

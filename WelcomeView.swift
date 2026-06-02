//
//  WelcomeView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-31.
//

import SwiftUI

/// Welcome screen shown when the app first launches
struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var navigateToProjects = false

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
}

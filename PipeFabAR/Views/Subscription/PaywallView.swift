import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false
    @State private var showPromoEntry = false
    @State private var promoCode = ""
    @State private var isRedeemingPromo = false
    @State private var promoMessage: String?

    private let privacyURL = URL(string: "https://www.missionintegratedsystems.com/privacy")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var priceString: String {
        guard let product = subscriptionManager.product else { return "Loading..." }
        return "\(product.displayPrice) / month"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.yellow)

                        Text("PipeFabAR Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Unlimited projects, work packages, and spools")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Feature comparison table
                    VStack(spacing: 0) {
                        // Column headers
                        HStack {
                            Text("Feature")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Free")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .center)
                            Text("Pro")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .frame(width: 70, alignment: .center)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color(.tertiarySystemGroupedBackground))

                        featureRow("Projects", free: "1", pro: "Unlimited")
                        Divider().padding(.leading)
                        featureRow("Work Packages", free: "1", pro: "Unlimited")
                        Divider().padding(.leading)
                        featureRow("Spools", free: "3", pro: "Unlimited")
                        Divider().padding(.leading)
                        featureRow("Isometric Drawing", free: "✓", pro: "✓")
                        Divider().padding(.leading)
                        featureRow("BOM Export & Email", free: "✓", pro: "✓")
                        Divider().padding(.leading)
                        featureRow("AR View", free: "✓", pro: "✓")
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    // Subscription details
                    VStack(spacing: 6) {
                        Text("PipeFabAR Pro Monthly")
                            .font(.headline)

                        Text(priceString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("Auto-renews monthly. Cancel anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Purchase button
                    Button {
                        Task { await subscriptionManager.purchase() }
                    } label: {
                        Group {
                            if subscriptionManager.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Subscribe — \(priceString)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(subscriptionManager.product == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(subscriptionManager.isPurchasing || subscriptionManager.product == nil)

                    // Promo code
                    Button("Have a promo code?") { showPromoEntry = true }
                        .font(.subheadline)
                        .foregroundColor(.blue)

                    // Restore purchases
                    Button {
                        Task {
                            isRestoring = true
                            await subscriptionManager.restore()
                            isRestoring = false
                            if subscriptionManager.isProSubscriber { dismiss() }
                        }
                    } label: {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Restore Purchases")
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(isRestoring)

                    // Legal links
                    HStack(spacing: 12) {
                        Link("Privacy Policy", destination: privacyURL)
                        Text("·").foregroundColor(.secondary)
                        Link("Terms of Use", destination: termsURL)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    // Required subscription disclosure
                    VStack(spacing: 4) {
                        Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscription in your App Store account settings.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Upgrade to Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
        }
        #if DEBUG
        .overlay(alignment: .topTrailing) {
            Button("Skip (Debug)") {
                subscriptionManager.debugUnlock()
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding()
        }
        #endif
        .alert("Enter Promo Code", isPresented: $showPromoEntry) {
            TextField("e.g. PIPEPRO2026", text: $promoCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            Button("Redeem") {
                let code = promoCode.trimmingCharacters(in: .whitespaces)
                promoCode = ""
                guard !code.isEmpty else { return }
                Task {
                    isRedeemingPromo = true
                    do {
                        let msg = try await BackendService.shared.redeemPromoCode(code)
                        promoMessage = msg
                        await subscriptionManager.refreshPromoStatus()
                    } catch {
                        promoMessage = error.localizedDescription
                    }
                    isRedeemingPromo = false
                }
            }
            Button("Cancel", role: .cancel) { promoCode = "" }
        }
        .alert("Promo Code", isPresented: Binding(
            get: { promoMessage != nil },
            set: { if !$0 { promoMessage = nil } }
        )) {
            Button("OK") { promoMessage = nil }
        } message: {
            Text(promoMessage ?? "")
        }
        .onChange(of: subscriptionManager.isProSubscriber) { _, isPro in
            if isPro { dismiss() }
        }
        .alert("Purchase Error", isPresented: Binding(
            get: { subscriptionManager.errorMessage != nil },
            set: { if !$0 { subscriptionManager.errorMessage = nil } }
        )) {
            Button("OK") { subscriptionManager.errorMessage = nil }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func featureRow(_ feature: String, free: String, pro: String) -> some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .center)
            Text(pro)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}

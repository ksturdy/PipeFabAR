import StoreKit
import Foundation

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isProSubscriber = false
    @Published private(set) var product: Product?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    static let productID = "com.missionintegratedsystems.pipefabar.pro.monthly"

    // Free tier limits
    static let freeProjectLimit = 1
    static let freeWorkPackageLimit = 1
    static let freeSpoolLimit = 3

    init() {}

    func start() {
        Task.detached(priority: .userInitiated) {
            await self.loadProduct()
            await self.refreshStatus()
            await self.listenForTransactions()
        }
    }

    func refreshPromoStatus() async {
        guard let expiresAt = await BackendService.shared.checkPromoStatus() else { return }
        if expiresAt > Date() {
            isProSubscriber = true
        }
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshStatus()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                hasActive = true
            }
        }
        // Check backend promo access if no active StoreKit subscription
        if !hasActive {
            if let expiresAt = await BackendService.shared.checkPromoStatus(), expiresAt > Date() {
                hasActive = true
            }
        }
        isProSubscriber = hasActive
    }

    #if DEBUG
    func debugUnlock() {
        isProSubscriber = true
    }
    #endif

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result {
                await tx.finish()
                await refreshStatus()
            }
        }
    }
}

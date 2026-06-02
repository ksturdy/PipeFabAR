import SwiftUI
import SwiftData

@main
struct PipeFabARApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        print("⏱ PipeFabARApp.body called \(Date())")
        return WindowGroup {
            WelcomeView()
                .modelContainer(DataController.shared.container)
                .environmentObject(subscriptionManager)
                .task { subscriptionManager.start() }
        }
    }
}

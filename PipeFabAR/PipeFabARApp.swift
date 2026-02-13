import SwiftUI
import SwiftData

@main
struct PipeFabARApp: App {
    let dataController = DataController.shared

    var body: some Scene {
        WindowGroup {
            WelcomeView()
                .modelContainer(dataController.container)
        }
    }
}

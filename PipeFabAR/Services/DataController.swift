//
//  DataController.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Manages SwiftData persistence for the app
class DataController {
    static let shared = DataController()
    let container: ModelContainer

    private init() {
        print("⏱ DataController.init START \(Date())")
        let schema = Schema([
            Project.self,
            WorkPackage.self,
            Spool.self,
            PipeSpecification.self
        ])
        print("⏱ Schema created \(Date())")

        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.missionintegrated.PipeFabAR")
        )
        print("⏱ ModelConfiguration created \(Date())")

        do {
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
            print("⏱ ModelContainer created with CloudKit \(Date())")
        } catch {
            print("⚠️ CloudKit ModelContainer failed: \(error.localizedDescription)")
            // Existing local store may have old schema — delete it and start fresh.
            // CloudKit will restore data from iCloud on next sync.
            DataController.deleteLocalStore()
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                container = try ModelContainer(for: schema, configurations: [localConfig])
                print("⏱ ModelContainer created locally after store reset \(Date())")
            } catch {
                fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
            }
        }
    }

    private static func deleteLocalStore() {
        let dir = URL.applicationSupportDirectory
        for name in ["default.store", "default.store-shm", "default.store-wal"] {
            try? FileManager.default.removeItem(at: dir.appending(path: name))
        }
        print("⚠️ Local store deleted for schema migration")
    }

    /// Create a sample project for testing/demo purposes
    func createSampleProject(in context: ModelContext) {
        let project = Project(
            name: "Sample Office Renovation",
            jobNumber: "2026-001",
            color: "#007AFF"
        )

        let package1 = WorkPackage(
            name: "Ground Floor",
            packageNumber: "001",
            status: "In Progress"
        )
        package1.project = project

        let package2 = WorkPackage(
            name: "Second Floor",
            packageNumber: "002",
            status: "Not Started"
        )
        package2.project = project

        project.workPackages = (project.workPackages ?? []) + [package1, package2]

        context.insert(project)

        do {
            try context.save()
        } catch {
            print("Failed to create sample project: \(error)")
        }
    }
}

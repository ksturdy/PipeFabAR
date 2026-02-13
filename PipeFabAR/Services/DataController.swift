//
//  DataController.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Manages SwiftData persistence for the app
@MainActor
class DataController {
    static let shared = DataController()
    let container: ModelContainer

    init() {
        let schema = Schema([
            Project.self,
            WorkPackage.self,
            Spool.self,
            PipeSpecification.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Future: Enable for iCloud sync
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            // Ensure default specifications exist
            let context = container.mainContext
            SpecificationManager.shared.ensureDefaultSpecifications(in: context)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error.localizedDescription)")
        }
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

        project.workPackages = [package1, package2]

        context.insert(project)

        do {
            try context.save()
        } catch {
            print("Failed to create sample project: \(error)")
        }
    }
}

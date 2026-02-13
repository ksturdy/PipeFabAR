//
//  SpecificationManager.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation
import SwiftData

/// Manages pipe specifications globally
@MainActor
final class SpecificationManager {
    static let shared = SpecificationManager()

    private init() {}

    /// Creates default specifications if none exist
    func ensureDefaultSpecifications(in context: ModelContext) {
        let descriptor = FetchDescriptor<PipeSpecification>()

        do {
            let existingSpecs = try context.fetch(descriptor)
            if existingSpecs.isEmpty {
                createDefaultSpecifications(in: context)
            }
        } catch {
            print("Error checking for existing specifications: \(error)")
        }
    }

    /// Creates the default set of pipe specifications
    private func createDefaultSpecifications(in context: ModelContext) {
        let defaults: [(description: String, abbreviation: String)] = [
            ("Carbon Steel Schedule 40", "CS SCH 40"),
            ("Carbon Steel Schedule 80", "CS SCH 80"),
            ("Stainless Steel Schedule 10", "SS SCH 10"),
            ("Stainless Steel Schedule 40", "SS SCH 40"),
            ("PVC Schedule 40", "PVC SCH 40"),
            ("PVC Schedule 80", "PVC SCH 80"),
            ("Copper Type K", "CU TYPE K"),
            ("Copper Type L", "CU TYPE L"),
            ("Copper Type M", "CU TYPE M")
        ]

        for (index, spec) in defaults.enumerated() {
            let specification = PipeSpecification(
                specDescription: spec.description,
                abbreviation: spec.abbreviation,
                sortOrder: index,
                isDefault: index == 0 // First one is default
            )
            context.insert(specification)
        }

        try? context.save()
    }

    /// Gets the default specification
    func getDefaultSpecification(in context: ModelContext) -> PipeSpecification? {
        var descriptor = FetchDescriptor<PipeSpecification>(
            predicate: #Predicate { $0.isDefault == true }
        )
        descriptor.fetchLimit = 1

        do {
            let specs = try context.fetch(descriptor)
            return specs.first
        } catch {
            print("Error fetching default specification: \(error)")
            return nil
        }
    }

    /// Sets a specification as the default (unsets any existing default)
    func setAsDefault(_ specification: PipeSpecification, in context: ModelContext) {
        let descriptor = FetchDescriptor<PipeSpecification>()

        do {
            let allSpecs = try context.fetch(descriptor)
            for spec in allSpecs {
                spec.isDefault = (spec.id == specification.id)
            }
            try context.save()
        } catch {
            print("Error setting default specification: \(error)")
        }
    }

    /// Gets all specifications sorted by sort order
    func getAllSpecifications(in context: ModelContext) -> [PipeSpecification] {
        var descriptor = FetchDescriptor<PipeSpecification>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching specifications: \(error)")
            return []
        }
    }
}

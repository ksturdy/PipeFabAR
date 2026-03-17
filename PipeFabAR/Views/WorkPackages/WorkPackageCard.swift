//
//  WorkPackageCard.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

/// Card displaying a work package
struct WorkPackageCard: View {
    @Bindable var workPackage: WorkPackage
    @Bindable var project: Project

    var statusColor: Color {
        switch workPackage.status {
        case "Not Started": return .gray
        case "In Progress": return .orange
        case "Review": return .blue
        case "Completed": return .green
        default: return .gray
        }
    }

    var body: some View {
        NavigationLink(destination: WorkPackageDetailView(workPackage: workPackage, project: project)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(workPackage.packageNumber) - \(workPackage.name)")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(workPackage.spoolCount) spools")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Status badge
                    Text(workPackage.status)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkPackageCard(
        workPackage: WorkPackage(
            name: "Ground Floor",
            packageNumber: "001",
            status: "In Progress"
        ),
        project: Project(
            name: "Sample Project",
            jobNumber: "2026"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

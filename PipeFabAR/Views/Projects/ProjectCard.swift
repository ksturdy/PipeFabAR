//
//  ProjectCard.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

/// Card displaying project summary information
struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator bar
            Rectangle()
                .fill(Color(hex: project.color) ?? .blue)
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 4) {
                // Project name
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Job number
                Text("Job #\(project.jobNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Stats
                HStack(spacing: 16) {
                    Label("\(project.totalSpoolCount)", systemImage: "cylinder.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(project.workPackageCount)", systemImage: "folder.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(project.modifiedDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ProjectCard(
        project: Project(
            name: "Office Renovation",
            jobNumber: "2026-001",
            color: "#007AFF"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

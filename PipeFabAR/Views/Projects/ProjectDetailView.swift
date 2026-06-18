//
//  ProjectDetailView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Detailed view of a project showing work packages and spools
struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedTab = 0
    @State private var showingAddPackageSheet = false
    @State private var showingSettings = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with sidebar
                iPadLayout()
            } else {
                // iPhone layout (original)
                iPhoneLayout()
            }
        }
        .navigationTitle(horizontalSizeClass == .regular ? "" : project.name)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                    Button {
                        // TODO: Export BOM
                    } label: {
                        Label("Export BOM", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        deleteProject()
                    } label: {
                        Label("Delete Project", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddPackageSheet) {
            CreateWorkPackageSheet(project: project)
        }
        .sheet(isPresented: $showingSettings) {
            EditProjectSheet(project: project)
        }
    }

    // MARK: - Layout Variants

    @ViewBuilder
    private func iPadLayout() -> some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Project header
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    Text("Job #\(project.jobNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Stats
                ProjectStatsHeader(project: project)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)

                Divider()

                // Navigation list
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        selectedTab = 0
                    } label: {
                        HStack {
                            Label("Work Packages", systemImage: "folder.fill")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedTab == 0 ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        selectedTab = 1
                    } label: {
                        HStack {
                            Label("All Spools", systemImage: "cylinder.fill")
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedTab == 1 ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(8)
            }
            .frame(width: PipeFabARTheme.sidebarWidth)
            .background(Color(.systemGroupedBackground))

            Divider()

            // Content area
            contentForSelectedTab()
        }
    }

    @ViewBuilder
    private func iPhoneLayout() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with stats
                ProjectStatsHeader(project: project)
                    .padding(.horizontal)

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Work Packages").tag(0)
                    Text("Spools").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                contentForSelectedTab()
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func contentForSelectedTab() -> some View {
        switch selectedTab {
        case 0:
            WorkPackagesSectionEnhanced(project: project, showingAddSheet: $showingAddPackageSheet)
        case 1:
            UnassignedSpoolsSectionEnhanced(project: project)
        default:
            EmptyView()
        }
    }

    // MARK: - Helper Functions

    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
    }
}

/// Header showing project statistics
struct ProjectStatsHeader: View {
    let project: Project

    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                value: "\(project.totalSpoolCount)",
                label: "Spools",
                icon: "cylinder.fill",
                color: .blue
            )

            Divider()
                .frame(height: 40)

            StatItem(
                value: "\(project.workPackageCount)",
                label: "Packages",
                icon: "folder.fill",
                color: .orange
            )

            Divider()
                .frame(height: 40)

            StatItem(
                value: "Job #\(project.jobNumber)",
                label: "Job Number",
                icon: "number",
                color: .green
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Temporary placeholder for work packages section
struct WorkPackagesSection: View {
    let project: Project
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Work Packages")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            if (project.workPackages ?? []).isEmpty {
                EmptyPackagesView(showingAddSheet: $showingAddSheet)
            } else {
                ForEach(project.workPackages ?? []) { package in
                    WorkPackageRow(package: package)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct EmptyPackagesView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Work Packages")
                .font(.headline)

            Text("Create a work package to organize your spools")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add Work Package")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct WorkPackageRow: View {
    let package: WorkPackage

    var statusColor: Color {
        switch package.status {
        case "Not Started": return .gray
        case "In Progress": return .orange
        case "Review": return .blue
        case "Completed": return .green
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(package.packageNumber) - \(package.name)")
                    .font(.headline)

                Text("\(package.spoolCount) spools")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(package.status)
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

/// Placeholder for spools section
struct UnassignedSpoolsSection: View {
    let project: Project

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Spools")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    // TODO: Create new spool
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            if (project.spools ?? []).isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cylinder.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("No Spools")
                        .font(.headline)

                    Text("Create spools and assign them to work packages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(project.spools ?? []) { spool in
                        Text(spool.name)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// Sheet for creating a work package
struct CreateWorkPackageSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let project: Project

    @State private var name = ""
    @State private var packageNumber = ""
    @State private var notes = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !packageNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Package Details")) {
                    TextField("Package Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Package Number", text: $packageNumber)
                        .textInputAutocapitalization(.characters)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Work Package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPackage()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createPackage() {
        let package = WorkPackage(
            name: name.trimmingCharacters(in: .whitespaces),
            packageNumber: packageNumber.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces),
            project: project
        )

        project.workPackages = (project.workPackages ?? []) + [package]
        modelContext.insert(package)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create work package: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(
            project: Project(
                name: "Office Renovation",
                jobNumber: "2026-001",
                color: "#007AFF"
            )
        )
    }
    .modelContainer(DataController.shared.container)
}

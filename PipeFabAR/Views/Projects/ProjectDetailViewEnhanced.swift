//
//  ProjectDetailViewEnhanced.swift
//  PipeFabAR
//
//  This file contains enhanced versions of sections with drag-and-drop support
//  Replace the sections in ProjectDetailView.swift with these
//

import SwiftUI
import SwiftData

/// Enhanced work packages section with drag-and-drop support
struct WorkPackagesSectionEnhanced: View {
    @Bindable var project: Project
    @Binding var showingAddSheet: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var showingPaywall = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Work Packages")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    if project.workPackages.count >= SubscriptionManager.freeWorkPackageLimit && !subscriptionManager.isProSubscriber {
                        showingPaywall = true
                    } else {
                        showingAddSheet = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $showingPaywall) {
                PaywallView().environmentObject(subscriptionManager)
            }

            if project.workPackages.isEmpty {
                EmptyPackagesView(showingAddSheet: $showingAddSheet)
            } else {
                List {
                    ForEach(project.workPackages) { package in
                        WorkPackageCard(workPackage: package, project: project)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteWorkPackage(package)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(project.workPackages.count) * 120)
            }
        }
    }

    private func deleteWorkPackage(_ package: WorkPackage) {
        // Move any assigned spools back to unassigned (project level)
        for spool in package.assignedSpools {
            spool.workPackage = nil
            project.spools.append(spool)
        }
        package.assignedSpools.removeAll()

        // Remove from project
        project.workPackages.removeAll { $0.id == package.id }

        // Delete from model context
        modelContext.delete(package)
        try? modelContext.save()
    }
}

/// Enhanced spools section with work package information
struct UnassignedSpoolsSectionEnhanced: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingCreateSpoolSheet = false
    @State private var showingPaywall = false
    @State private var selectedSpoolID: UUID? = nil

    // Get all spools from project and work packages
    var allSpools: [Spool] {
        var spools: [Spool] = []

        // Add unassigned spools from project
        spools.append(contentsOf: project.spools)

        // Add spools from all work packages
        for package in project.workPackages {
            spools.append(contentsOf: package.assignedSpools)
        }

        // Sort by name
        return spools.sorted { $0.name < $1.name }
    }

    var selectedSpool: Spool? {
        guard let id = selectedSpoolID else { return nil }
        return allSpools.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Spools")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    if project.totalSpoolCount >= SubscriptionManager.freeSpoolLimit && !subscriptionManager.isProSubscriber {
                        showingPaywall = true
                    } else {
                        showingCreateSpoolSheet = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .padding(.horizontal)

            if allSpools.isEmpty {
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

                    Button {
                        // Empty state only shows when count is 0, always within free limit
                        showingCreateSpoolSheet = true
                    } label: {
                        Text("Create Spool")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(allSpools) { spool in
                        Button {
                            selectedSpoolID = spool.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(spool.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    if let workPackage = spool.workPackage {
                                        Text("PKG #\(workPackage.packageNumber) - \(workPackage.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Unassigned")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingCreateSpoolSheet) {
            CreateSpoolSheet(project: project)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView().environmentObject(subscriptionManager)
        }
        .navigationDestination(item: Binding(
            get: { selectedSpool },
            set: { newValue in
                selectedSpoolID = newValue?.id
            }
        )) { spool in
            SpoolDetailView(spool: spool)
        }
    }
}

/// Sheet for creating a new spool
struct CreateSpoolSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PipeSpecification.sortOrder) private var specifications: [PipeSpecification]

    @Bindable var project: Project
    var preselectedWorkPackage: WorkPackage? = nil

    @State private var selectedSystemType: SystemType? = nil
    @State private var selectedWorkPackage: WorkPackage? = nil
    @State private var selectedSpecification: PipeSpecification?
    @State private var useInheritedSpec: Bool = true

    var spoolName: String {
        SpoolNamingService.generateName(project: project, workPackage: selectedWorkPackage)
    }

    var inheritedSpec: PipeSpecification? {
        selectedWorkPackage?.effectivePipeSpecification ?? project.defaultPipeSpecification
    }

    init(project: Project, preselectedWorkPackage: WorkPackage? = nil) {
        self.project = project
        self.preselectedWorkPackage = preselectedWorkPackage
        _selectedWorkPackage = State(initialValue: preselectedWorkPackage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Spool Name")) {
                    Text(spoolName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)

                    Text("Auto-generated from template")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("System Type (Optional)")) {
                    Picker("System", selection: $selectedSystemType) {
                        Text("None").tag(nil as SystemType?)
                        ForEach(SystemType.allCases, id: \.self) { systemType in
                            HStack {
                                Image(systemName: systemType.icon)
                                Text(systemType.rawValue)
                            }
                            .tag(systemType as SystemType?)
                        }
                    }
                }

                Section(header: Text("Assign to Work Package (Optional)")) {
                    Picker("Work Package", selection: $selectedWorkPackage) {
                        Text("Unassigned").tag(nil as WorkPackage?)
                        ForEach(project.workPackages) { package in
                            Text("\(package.name) (PKG #\(package.packageNumber))")
                                .tag(package as WorkPackage?)
                        }
                    }
                }

                Section(header: Text("Pipe Specification")) {
                    Toggle("Use Inherited Spec", isOn: $useInheritedSpec)

                    if useInheritedSpec {
                        if let spec = inheritedSpec {
                            HStack {
                                Text("Inherited")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(spec.abbreviation)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("No specification set on project/package")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Specification", selection: $selectedSpecification) {
                            Text("None").tag(nil as PipeSpecification?)
                            ForEach(specifications) { spec in
                                Text("\(spec.abbreviation) - \(spec.specDescription)")
                                    .tag(spec as PipeSpecification?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }

                Section {
                    Text("You can draw the pipe routing after creating the spool")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Spool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSpool()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createSpool() {
        let spool = Spool(
            name: spoolName,
            systemType: selectedSystemType?.rawValue,
            status: "Draft",
            pipeSpecificationOverride: useInheritedSpec ? nil : selectedSpecification,
            project: project
        )

        // Increment project spool counter
        project.nextSpoolNumber += 1

        if let workPackage = selectedWorkPackage {
            spool.workPackage = workPackage
            workPackage.assignedSpools.append(spool)
        } else {
            project.spools.append(spool)
        }

        modelContext.insert(spool)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create spool: \(error)")
        }
    }
}

#Preview {
    CreateSpoolSheet(
        project: Project(
            name: "Office Renovation",
            jobNumber: "2026",
            color: "#007AFF"
        )
    )
    .modelContainer(DataController.shared.container)
}

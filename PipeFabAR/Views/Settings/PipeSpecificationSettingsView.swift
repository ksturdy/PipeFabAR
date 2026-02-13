//
//  PipeSpecificationSettingsView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Main Settings view with User Profile and Pipe Specifications
struct PipeSpecificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PipeSpecification.sortOrder) private var specifications: [PipeSpecification]
    @ObservedObject private var userProfile = UserProfile.shared

    @State private var showingAddSheet = false
    @State private var editingSpecification: PipeSpecification?
    @State private var userName: String = ""
    @State private var userPhone: String = ""
    @State private var userEmail: String = ""

    var body: some View {
        NavigationStack {
            List {
                // User Profile Section
                Section {
                    TextField("Name", text: $userName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: userName) { _, newValue in
                            userProfile.name = newValue
                        }

                    TextField("Phone Number", text: $userPhone)
                        .keyboardType(.phonePad)
                        .onChange(of: userPhone) { _, newValue in
                            userProfile.phoneNumber = newValue
                        }

                    TextField("Email", text: $userEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: userEmail) { _, newValue in
                            userProfile.email = newValue
                        }
                } header: {
                    Text("User Profile")
                } footer: {
                    Text("Your information will appear on spool sheets and package cover pages.")
                }

                // Pipe Specifications Section
                Section {
                    ForEach(specifications) { spec in
                        SpecificationRow(
                            specification: spec,
                            onSetDefault: { setAsDefault(spec) },
                            onEdit: { editingSpecification = spec }
                        )
                    }
                    .onDelete(perform: deleteSpecifications)
                    .onMove(perform: moveSpecifications)

                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Specification", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Pipe Specifications")
                } footer: {
                    Text("Default specification will be pre-selected when creating new projects.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditSpecificationSheet(specification: nil)
            }
            .sheet(item: $editingSpecification) { spec in
                AddEditSpecificationSheet(specification: spec)
            }
            .onAppear {
                userName = userProfile.name
                userPhone = userProfile.phoneNumber
                userEmail = userProfile.email
            }
        }
    }

    private func setAsDefault(_ specification: PipeSpecification) {
        SpecificationManager.shared.setAsDefault(specification, in: modelContext)
    }

    private func deleteSpecifications(at offsets: IndexSet) {
        for index in offsets {
            let spec = specifications[index]
            modelContext.delete(spec)
        }
        try? modelContext.save()
    }

    private func moveSpecifications(from source: IndexSet, to destination: Int) {
        var specs = specifications
        specs.move(fromOffsets: source, toOffset: destination)
        for (index, spec) in specs.enumerated() {
            spec.sortOrder = index
        }
        try? modelContext.save()
    }
}

/// Row displaying a single specification
struct SpecificationRow: View {
    let specification: PipeSpecification
    let onSetDefault: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(specification.specDescription)
                        .font(.body)
                    if specification.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .cornerRadius(4)
                    }
                }
                Text(specification.abbreviation)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .leading) {
            if !specification.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Default", systemImage: "star.fill")
                }
                .tint(.orange)
            }
        }
    }
}

/// Sheet for adding or editing a specification
struct AddEditSpecificationSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let specification: PipeSpecification?

    @State private var specDescription: String = ""
    @State private var abbreviation: String = ""

    var isEditing: Bool {
        specification != nil
    }

    var isValid: Bool {
        !specDescription.trimmingCharacters(in: .whitespaces).isEmpty &&
        !abbreviation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Description", text: $specDescription)
                        .textInputAutocapitalization(.words)
                    TextField("Abbreviation", text: $abbreviation)
                        .textInputAutocapitalization(.characters)
                } header: {
                    Text("Specification Details")
                } footer: {
                    Text("Example: Carbon Steel Schedule 40 (CS SCH 40)")
                }
            }
            .navigationTitle(isEditing ? "Edit Specification" : "New Specification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveSpecification()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let spec = specification {
                    specDescription = spec.specDescription
                    abbreviation = spec.abbreviation
                }
            }
        }
    }

    private func saveSpecification() {
        if let spec = specification {
            // Update existing
            spec.specDescription = specDescription.trimmingCharacters(in: .whitespaces)
            spec.abbreviation = abbreviation.trimmingCharacters(in: .whitespaces)
        } else {
            // Create new
            let specs = SpecificationManager.shared.getAllSpecifications(in: modelContext)
            let maxOrder = specs.map(\.sortOrder).max() ?? -1

            let newSpec = PipeSpecification(
                specDescription: specDescription.trimmingCharacters(in: .whitespaces),
                abbreviation: abbreviation.trimmingCharacters(in: .whitespaces),
                sortOrder: maxOrder + 1,
                isDefault: specs.isEmpty
            )
            modelContext.insert(newSpec)
        }
        try? modelContext.save()
    }
}

#Preview {
    PipeSpecificationSettingsView()
        .modelContainer(DataController.shared.container)
}

//
//  EditWorkPackageSheet.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Sheet for editing an existing work package
struct EditWorkPackageSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PipeSpecification.sortOrder) private var specifications: [PipeSpecification]

    @Bindable var workPackage: WorkPackage

    @State private var name: String
    @State private var packageNumber: String
    @State private var notes: String
    @State private var status: String
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var selectedSpecification: PipeSpecification?
    @State private var useProjectDefault: Bool

    init(workPackage: WorkPackage) {
        self.workPackage = workPackage
        _name = State(initialValue: workPackage.name)
        _packageNumber = State(initialValue: workPackage.packageNumber)
        _notes = State(initialValue: workPackage.notes)
        _status = State(initialValue: workPackage.status)
        _dueDate = State(initialValue: workPackage.dueDate ?? Date())
        _hasDueDate = State(initialValue: workPackage.dueDate != nil)
        _selectedSpecification = State(initialValue: workPackage.pipeSpecificationOverride)
        _useProjectDefault = State(initialValue: workPackage.pipeSpecificationOverride == nil)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !packageNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasChanges: Bool {
        name != workPackage.name ||
        packageNumber != workPackage.packageNumber ||
        notes != workPackage.notes ||
        status != workPackage.status ||
        (hasDueDate ? dueDate : nil) != workPackage.dueDate ||
        specificationChanged
    }

    var specificationChanged: Bool {
        if useProjectDefault {
            return workPackage.pipeSpecificationOverride != nil
        } else {
            return selectedSpecification?.id != workPackage.pipeSpecificationOverride?.id
        }
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

                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        ForEach(WorkPackage.Status.allCases, id: \.rawValue) { statusOption in
                            Text(statusOption.rawValue).tag(statusOption.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section(header: Text("Pipe Specification")) {
                    Toggle("Use Project Default", isOn: $useProjectDefault)

                    if !useProjectDefault {
                        Picker("Specification", selection: $selectedSpecification) {
                            Text("None").tag(nil as PipeSpecification?)
                            ForEach(specifications) { spec in
                                Text("\(spec.abbreviation) - \(spec.specDescription)")
                                    .tag(spec as PipeSpecification?)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    if let effectiveSpec = useProjectDefault ? workPackage.project?.defaultPipeSpecification : selectedSpecification {
                        HStack {
                            Text("Effective")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(effectiveSpec.abbreviation)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Created")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(workPackage.createdDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Assigned Spools")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(workPackage.spoolCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Work Package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid || !hasChanges)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        workPackage.name = name.trimmingCharacters(in: .whitespaces)
        workPackage.packageNumber = packageNumber.trimmingCharacters(in: .whitespaces)
        workPackage.notes = notes.trimmingCharacters(in: .whitespaces)
        workPackage.status = status
        workPackage.dueDate = hasDueDate ? dueDate : nil
        workPackage.pipeSpecificationOverride = useProjectDefault ? nil : selectedSpecification

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update work package: \(error)")
        }
    }
}

#Preview {
    EditWorkPackageSheet(
        workPackage: WorkPackage(
            name: "First Floor Piping",
            packageNumber: "001",
            status: "In Progress",
            notes: "Main mechanical room installation"
        )
    )
    .modelContainer(DataController.shared.container)
}

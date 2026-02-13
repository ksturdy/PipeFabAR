//
//  EditProjectSheet.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Sheet for editing an existing project
struct EditProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \PipeSpecification.sortOrder) private var specifications: [PipeSpecification]

    @Bindable var project: Project

    @State private var name: String
    @State private var jobNumber: String
    @State private var selectedColor: Color
    @State private var selectedSpecification: PipeSpecification?

    // Color palette
    private let colorOptions: [(String, Color)] = [
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Teal", .teal),
        ("Indigo", .indigo),
        ("Brown", .brown)
    ]

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _jobNumber = State(initialValue: project.jobNumber)
        _selectedColor = State(initialValue: Color(hex: project.color) ?? .blue)
        _selectedSpecification = State(initialValue: project.defaultPipeSpecification)
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var hasChanges: Bool {
        name != project.name ||
        jobNumber != project.jobNumber ||
        selectedColor.toHex() != project.color ||
        selectedSpecification?.id != project.defaultPipeSpecification?.id
    }

    private var colorGridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            // iPad: Fixed 5 columns
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
        } else {
            // iPhone: Adaptive
            return [GridItem(.adaptive(minimum: 50), spacing: 12)]
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Job Number", text: $jobNumber)
                        .textInputAutocapitalization(.characters)
                }

                Section(header: Text("Project Color")) {
                    LazyVGrid(columns: colorGridColumns, spacing: 12) {
                        ForEach(colorOptions, id: \.0) { colorName, color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedColor = color
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Default Pipe Specification")) {
                    Picker("Specification", selection: $selectedSpecification) {
                        Text("None").tag(nil as PipeSpecification?)
                        ForEach(specifications) { spec in
                            Text("\(spec.abbreviation) - \(spec.specDescription)")
                                .tag(spec as PipeSpecification?)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if selectedSpecification != nil {
                        Text("Default specification for all packages and spools in this project")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Naming Template")) {
                    Text(project.spoolNamingTemplate)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text("Example: \(jobNumber.isEmpty ? "2026" : jobNumber)-001-001")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    HStack {
                        Text("Created")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(project.createdDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Last Modified")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(project.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? PipeFabARTheme.maxFormWidth : .infinity)
            .frame(maxWidth: .infinity) // Centers the max-width frame
            .navigationTitle("Edit Project")
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
        project.name = name.trimmingCharacters(in: .whitespaces)
        project.jobNumber = jobNumber.trimmingCharacters(in: .whitespaces)
        project.color = selectedColor.toHex() ?? project.color
        project.defaultPipeSpecification = selectedSpecification
        project.modifiedDate = Date()

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to update project: \(error)")
        }
    }
}

#Preview {
    EditProjectSheet(
        project: Project(
            name: "Office Renovation",
            jobNumber: "2026-001",
            color: "#007AFF"
        )
    )
    .modelContainer(DataController.shared.container)
}

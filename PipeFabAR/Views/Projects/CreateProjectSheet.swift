//
//  CreateProjectSheet.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Sheet for creating a new project
struct CreateProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \PipeSpecification.sortOrder) private var specifications: [PipeSpecification]

    @State private var name = ""
    @State private var jobNumber = ""
    @State private var selectedColor = Color.blue
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

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !jobNumber.trimmingCharacters(in: .whitespaces).isEmpty
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

                Section(header: Text("Pipe Specification")) {
                    Picker("Default Specification", selection: $selectedSpecification) {
                        Text("None").tag(nil as PipeSpecification?)
                        ForEach(specifications) { spec in
                            Text("\(spec.abbreviation) - \(spec.specDescription)")
                                .tag(spec as PipeSpecification?)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    if let spec = selectedSpecification {
                        Text("All spools will default to \(spec.abbreviation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Naming Template")) {
                    Text("{jobNumber}-{packageNumber}-{spoolNumber}")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text("Example: \(jobNumber.isEmpty ? "2026" : jobNumber)-001-001")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: horizontalSizeClass == .regular ? PipeFabARTheme.maxFormWidth : .infinity)
            .frame(maxWidth: .infinity) // Centers the max-width frame
            .onAppear {
                // Select the default specification
                if selectedSpecification == nil {
                    selectedSpecification = specifications.first { $0.isDefault }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createProject() {
        let project = Project(
            name: name.trimmingCharacters(in: .whitespaces),
            jobNumber: jobNumber.trimmingCharacters(in: .whitespaces),
            color: selectedColor.toHex() ?? "#007AFF",
            defaultPipeSpecification: selectedSpecification
        )

        modelContext.insert(project)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create project: \(error)")
        }
    }
}

#Preview {
    CreateProjectSheet()
        .modelContainer(DataController.shared.container)
}

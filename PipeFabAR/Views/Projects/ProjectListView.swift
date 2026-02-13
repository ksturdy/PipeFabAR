//
//  ProjectListView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData

/// Root view displaying list of all projects
struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Project.modifiedDate, order: .reverse) private var projects: [Project]

    @State private var showingCreateSheet = false
    @State private var showingSettings = false
    @State private var searchText = ""

    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.jobNumber.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if filteredProjects.isEmpty {
                EmptyProjectsView(showingCreateSheet: $showingCreateSheet)
            } else {
                ScrollView {
                    if horizontalSizeClass == .regular {
                        // iPad: 2-column grid
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ],
                            spacing: 20
                        ) {
                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(24) // More padding on iPad
                    } else {
                        // iPhone: Single column
                        LazyVStack(spacing: 16) {
                            ForEach(filteredProjects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Label("New Project", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateProjectSheet()
        }
        .sheet(isPresented: $showingSettings) {
            PipeSpecificationSettingsView()
        }
    }
}

/// Empty state view when no projects exist
struct EmptyProjectsView: View {
    @Binding var showingCreateSheet: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Projects Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first project to start organizing your pipe routing work")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingCreateSheet = true
            } label: {
                Label("Create Project", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ProjectListView()
        .modelContainer(DataController.shared.container)
}

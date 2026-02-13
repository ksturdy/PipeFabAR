//
//  WorkPackageDetailView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI
import SwiftData
import MessageUI

/// Detailed view of a work package showing its information and assigned spools
struct WorkPackageDetailView: View {
    @Bindable var workPackage: WorkPackage
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showingEditSheet = false
    @State private var showingCreateSpoolSheet = false
    @State private var spoolToView: Spool? = nil
    @State private var spoolToEdit: Spool? = nil
    @State private var spoolToMove: Spool? = nil
    @State private var spoolToEmail: Spool? = nil
    @State private var showingMailError = false
    @State private var showingPackageEmail = false
    @State private var showingPackagePreview = false

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
        Group {
            if horizontalSizeClass == .regular {
                // iPad layout with split view
                iPadLayout()
            } else {
                // iPhone layout (original)
                iPhoneLayout()
            }
        }
        .navigationTitle("\(workPackage.packageNumber) - \(workPackage.name)")
        .navigationBarTitleDisplayMode(horizontalSizeClass == .regular ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // Preview Package button
                    Button {
                        showingPackagePreview = true
                    } label: {
                        Label("Preview Package", systemImage: "doc.richtext")
                    }
                    .disabled(workPackage.assignedSpools.isEmpty)

                    // Send Package button
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showingPackageEmail = true
                        } else {
                            showingMailError = true
                        }
                    } label: {
                        Label("Send Package", systemImage: "paperplane.fill")
                    }
                    .disabled(workPackage.assignedSpools.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWorkPackageSheet(workPackage: workPackage)
        }
        .sheet(isPresented: $showingCreateSpoolSheet) {
            CreateSpoolSheet(project: project, preselectedWorkPackage: workPackage)
        }
        .sheet(item: $spoolToMove) { spool in
            MoveSpoolSheet(spool: spool, project: project, currentPackage: workPackage)
        }
        .navigationDestination(item: $spoolToView) { spool in
            SpoolPrintableView(spool: spool, project: project, workPackage: workPackage)
        }
        .navigationDestination(item: $spoolToEdit) { spool in
            SpoolDetailView(spool: spool)
        }
        .sheet(item: $spoolToEmail) { spool in
            SpoolMailComposer(
                spool: spool,
                project: project,
                workPackage: workPackage,
                isPresented: Binding(
                    get: { spoolToEmail != nil },
                    set: { if !$0 { spoolToEmail = nil } }
                )
            )
        }
        .alert("Cannot Send Email", isPresented: $showingMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please configure an email account in Settings to send emails.")
        }
        .sheet(isPresented: $showingPackageEmail) {
            WorkPackageMailComposer(
                workPackage: workPackage,
                project: project,
                isPresented: $showingPackageEmail
            )
        }
        .fullScreenCover(isPresented: $showingPackagePreview) {
            PackagePreviewView(
                workPackage: workPackage,
                project: project,
                isPresented: $showingPackagePreview
            )
        }
    }

    // MARK: - Layout Variants

    @ViewBuilder
    private func iPadLayout() -> some View {
        HStack(spacing: 0) {
            // Package info sidebar
            packageInfoSidebar()
                .frame(width: PipeFabARTheme.wideSidebarWidth)
                .background(Color(.systemGroupedBackground))

            Divider()

            // Spools list
            spoolsListSection()
        }
    }

    @ViewBuilder
    private func iPhoneLayout() -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Work Package Info Card
                packageInfoCard()
                    .padding(.horizontal)

                // Spools Section
                spoolsSection()
            }
            .padding(.vertical)
        }
    }

    @ViewBuilder
    private func packageInfoSidebar() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(workPackage.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("PKG #\(workPackage.packageNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Status
                HStack {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text(workPackage.status)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.15))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }

                // Stats
                VStack(spacing: 12) {
                    statRow(label: "Total Spools", value: "\(workPackage.spoolCount)")

                    if let spec = workPackage.effectivePipeSpecification {
                        HStack {
                            Text("Pipe Spec")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(spec.abbreviation)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if workPackage.pipeSpecificationOverride == nil {
                                    Text("(from project)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // Notes
                if !workPackage.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(workPackage.notes)
                            .font(.subheadline)
                    }
                }

                Divider()

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Package", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingPackagePreview = true
                    } label: {
                        Label("Preview Package", systemImage: "doc.richtext")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(workPackage.assignedSpools.isEmpty)

                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showingPackageEmail = true
                        } else {
                            showingMailError = true
                        }
                    } label: {
                        Label("Send Package", systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(workPackage.assignedSpools.isEmpty)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func spoolsListSection() -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Spools (\(workPackage.assignedSpools.count))")
                    .font(.headline)

                Spacer()

                Button {
                    showingCreateSpoolSheet = true
                } label: {
                    Label("Add Spool", systemImage: "plus.circle.fill")
                }
            }
            .padding()
            .background(Color(.systemGroupedBackground))

            Divider()

            // Spool grid
            if workPackage.assignedSpools.isEmpty {
                emptySpoolsView()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 250), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(workPackage.assignedSpools.sorted { $0.name < $1.name }) { spool in
                            spoolCardView(spool)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private func spoolCardView(_ spool: Spool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Spool name and system type
            VStack(alignment: .leading, spacing: 4) {
                Text(spool.name)
                    .font(.body)
                    .fontWeight(.semibold)

                if let systemType = spool.systemType {
                    Text(systemType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    spoolToEdit = spool
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    spoolToView = spool
                } label: {
                    Label("View", systemImage: "doc.text")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Menu {
                    Button {
                        spoolToMove = spool
                    } label: {
                        Label("Move", systemImage: "arrow.right.circle")
                    }

                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            spoolToEmail = spool
                        } else {
                            showingMailError = true
                        }
                    } label: {
                        Label("Email", systemImage: "envelope")
                    }

                    Divider()

                    Button(role: .destructive) {
                        deleteSpool(spool)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func packageInfoCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Package Information")
                    .font(.headline)

                Spacer()

                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }

            Divider()

            // Package Number
            HStack {
                Text("Package Number:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("PKG #\(workPackage.packageNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Status
            HStack {
                Text("Status:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(workPackage.status)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }

            // Spool Count
            statRow(label: "Total Spools:", value: "\(workPackage.spoolCount)")

            // Pipe Specification
            HStack {
                Text("Pipe Spec:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if let spec = workPackage.effectivePipeSpecification {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(spec.abbreviation)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if workPackage.pipeSpecificationOverride == nil {
                            Text("(from project)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Not Set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Notes
            if !workPackage.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(workPackage.notes)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func spoolsSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Spools")
                    .font(.headline)

                Spacer()

                Button {
                    showingCreateSpoolSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Spool")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            if workPackage.assignedSpools.isEmpty {
                emptySpoolsView()
            } else {
                List {
                    ForEach(workPackage.assignedSpools.sorted { $0.name < $1.name }) { spool in
                        HStack {
                            // Spool info
                            Button {
                                spoolToEdit = spool
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(spool.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)

                                    if let systemType = spool.systemType {
                                        Text(systemType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // Action buttons
                            Button {
                                spoolToView = spool
                            } label: {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)

                            Button {
                                spoolToMove = spool
                            } label: {
                                Image(systemName: "arrow.right.circle")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)

                            Button {
                                if MFMailComposeViewController.canSendMail() {
                                    spoolToEmail = spool
                                } else {
                                    showingMailError = true
                                }
                            } label: {
                                Image(systemName: "envelope.circle")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteSpool(spool)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(workPackage.assignedSpools.count) * 70)
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func emptySpoolsView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "cylinder.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Spools")
                .font(.headline)

            Text("Add spools to this work package")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateSpoolSheet = true
            } label: {
                Text("Add Spool")
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
    }

    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Helper Functions

    private func deleteSpool(_ spool: Spool) {
        // Remove from work package's assigned spools
        workPackage.assignedSpools.removeAll { $0.id == spool.id }
        // Delete from model context
        modelContext.delete(spool)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        WorkPackageDetailView(
            workPackage: WorkPackage(
                name: "Ground Floor",
                packageNumber: "001",
                status: "In Progress",
                notes: "First floor installation"
            ),
            project: Project(
                name: "Sample Project",
                jobNumber: "2026"
            )
        )
    }
    .modelContainer(DataController.shared.container)
}

// MARK: - Work Package Mail Composer

struct WorkPackageMailComposer: UIViewControllerRepresentable {
    let workPackage: WorkPackage
    let project: Project
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator

        // Set subject
        let subject = "\(project.name) - PKG \(workPackage.packageNumber) - \(workPackage.name)"
        composer.setSubject(subject)

        // Generate multi-page PDF binder and attach
        if let pdfData = generatePackagePDF() {
            let filename = "Package_\(workPackage.packageNumber)_\(workPackage.name).pdf"
                .replacingOccurrences(of: " ", with: "_")
            composer.addAttachmentData(pdfData, mimeType: "application/pdf", fileName: filename)
        }

        // Body text
        let spoolCount = workPackage.assignedSpools.count
        let body = """
        Please find attached the work package binder for:

        Project: \(project.name)
        Job #: \(project.jobNumber)
        Package: \(workPackage.name) (PKG #\(workPackage.packageNumber))
        Status: \(workPackage.status)
        Total Spools: \(spoolCount)

        This PDF binder includes:
        • Cover page with project information
        • Aggregated bill of materials
        • \(spoolCount) spool sheet(s)

        """
        composer.setMessageBody(body, isHTML: false)

        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    func generatePackagePDF() -> Data? {
        let pageWidth: CGFloat = 11 * 72  // 792 points
        let pageHeight: CGFloat = 8.5 * 72  // 612 points
        let pageSize = CGSize(width: pageWidth, height: pageHeight)

        let pdfData = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }

        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }

        // Page 1: Cover page
        let coverView = PackageCoverPageView(workPackage: workPackage, project: project)
        let coverRenderer = ImageRenderer(content:
            coverView
                .frame(width: pageWidth, height: pageHeight)
                .background(Color.white)
        )
        coverRenderer.scale = 2.0

        coverRenderer.render { _, renderContext in
            context.beginPDFPage(nil)
            renderContext(context)
            context.endPDFPage()
        }

        // Page 2: Aggregated BOM
        let bomView = PackageAggregatedBOMView(workPackage: workPackage, project: project)
        let bomRenderer = ImageRenderer(content:
            bomView
                .frame(width: pageWidth, height: pageHeight)
                .background(Color.white)
        )
        bomRenderer.scale = 2.0

        bomRenderer.render { _, renderContext in
            context.beginPDFPage(nil)
            renderContext(context)
            context.endPDFPage()
        }

        // Remaining pages: Individual spool sheets
        let sortedSpools = workPackage.assignedSpools.sorted { $0.name < $1.name }
        for spool in sortedSpools {
            let spoolView = SpoolPDFView(spool: spool, project: project, workPackage: workPackage)
            let spoolRenderer = ImageRenderer(content:
                spoolView
                    .frame(width: pageWidth, height: pageHeight)
                    .background(Color.white)
            )
            spoolRenderer.scale = 2.0

            spoolRenderer.render { _, renderContext in
                context.beginPDFPage(nil)
                renderContext(context)
                context.endPDFPage()
            }
        }

        context.closePDF()
        return pdfData as Data
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: WorkPackageMailComposer

        init(_ parent: WorkPackageMailComposer) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.isPresented = false
        }
    }
}

// MARK: - Cover Page View

struct PackageCoverPageView: View {
    let workPackage: WorkPackage
    let project: Project

    let pageWidth: CGFloat = 11 * 72
    let pageHeight: CGFloat = 8.5 * 72
    let pageMargin: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title section
            VStack(spacing: 16) {
                Text("WORK PACKAGE")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(4)

                Text(workPackage.name)
                    .font(.system(size: 36, weight: .bold))

                Text("PKG #\(workPackage.packageNumber)")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
            }

            Spacer()
                .frame(height: 60)

            // Divider line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 300, height: 1)

            Spacer()
                .frame(height: 60)

            // Project info section
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROJECT")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(project.name)
                            .font(.system(size: 18, weight: .semibold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("JOB NUMBER")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(project.jobNumber)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATUS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(workPackage.status)
                            .font(.system(size: 16))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .foregroundColor(statusColor)
                            .cornerRadius(6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL SPOOLS")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(workPackage.assignedSpools.count)")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }

                if let spec = workPackage.effectivePipeSpecification {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PIPE SPECIFICATION")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(spec.abbreviation)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }

            Spacer()
                .frame(height: 60)

            // Notes section (if any)
            if !workPackage.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(workPackage.notes)
                        .font(.system(size: 12))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
            }

            Spacer()

            // Prepared By section
            VStack(spacing: 12) {
                if UserProfile.shared.hasProfile {
                    VStack(spacing: 4) {
                        Text("PREPARED BY")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(UserProfile.shared.displayName)
                            .font(.system(size: 14, weight: .semibold))

                        if !UserProfile.shared.displayPhone.isEmpty {
                            Text(UserProfile.shared.displayPhone)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        if !UserProfile.shared.displayEmail.isEmpty {
                            Text(UserProfile.shared.displayEmail)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 1)

                // Footer with date
                HStack(spacing: 20) {
                    Text("Generated: \(Date(), style: .date)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text("Page 1")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, pageMargin)
        }
        .frame(width: pageWidth, height: pageHeight)
        .background(Color.white)
    }

    var statusColor: Color {
        switch workPackage.status {
        case "Not Started": return .gray
        case "In Progress": return .orange
        case "Review": return .blue
        case "Completed": return .green
        default: return .gray
        }
    }
}

// MARK: - Aggregated BOM View

struct PackageAggregatedBOMView: View {
    let workPackage: WorkPackage
    let project: Project

    let pageWidth: CGFloat = 11 * 72
    let pageHeight: CGFloat = 8.5 * 72
    let pageMargin: CGFloat = 30
    let scale: CGFloat = 2.0

    // Fitting item for aggregation
    struct AggregatedFittingItem: Hashable {
        let fittingType: FittingType
        let enteringSize: PipeSize
        let exitingSize: PipeSize
        let isInferred: Bool

        var sizeDescription: String {
            if enteringSize == .none && exitingSize == .none {
                return "—"
            } else if enteringSize == .none {
                return exitingSize.shortName
            } else if exitingSize == .none {
                return enteringSize.shortName
            } else if enteringSize == exitingSize {
                return enteringSize.shortName
            } else {
                return "\(enteringSize.shortName)×\(exitingSize.shortName)"
            }
        }

        // Unique key for grouping
        var groupKey: String {
            "\(fittingType.rawValue)|\(enteringSize.rawValue)|\(exitingSize.rawValue)|\(isInferred)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AGGREGATED BILL OF MATERIALS")
                        .font(.system(size: 14, weight: .bold))

                    Text("\(project.name) - PKG #\(workPackage.packageNumber) - \(workPackage.name)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Page 2")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, pageMargin)
            .padding(.top, pageMargin)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, pageMargin)

            // Content area
            HStack(alignment: .top, spacing: 30) {
                // Fittings summary
                fittingsSummaryView()
                    .frame(maxWidth: .infinity)

                // Pipe lengths summary
                pipeLengthsSummaryView()
                    .frame(maxWidth: .infinity)
            }
            .padding(pageMargin)

            Spacer()

            // Spool listing
            spoolListingView()
                .padding(.horizontal, pageMargin)
                .padding(.bottom, pageMargin)
        }
        .frame(width: pageWidth, height: pageHeight)
        .background(Color.white)
    }

    // Aggregated fitting counts across all spools (including inferred elbows)
    var aggregatedFittings: [(AggregatedFittingItem, Int)] {
        var counts: [String: (AggregatedFittingItem, Int)] = [:]

        for spool in workPackage.assignedSpools {
            let pipePoints = spool.pipePoints

            for (index, point) in pipePoints.enumerated() {
                let isFirst = index == 0
                let isLast = index == pipePoints.count - 1

                let enteringSize: PipeSize = isFirst ? .none : pipePoints[index - 1].pipeSize
                let exitingSize: PipeSize = isLast ? .none : pipePoints[index].pipeSize

                // Explicit fittings
                if point.fittingType != .none {
                    let item = AggregatedFittingItem(
                        fittingType: point.fittingType,
                        enteringSize: enteringSize,
                        exitingSize: exitingSize,
                        isInferred: false
                    )
                    let key = item.groupKey
                    if let existing = counts[key] {
                        counts[key] = (existing.0, existing.1 + 1)
                    } else {
                        counts[key] = (item, 1)
                    }
                }
                // Inferred elbows from direction changes
                else if !isFirst && !isLast {
                    let prevPoint = pipePoints[index - 1].position
                    let currentPoint = point.position
                    let nextPoint = pipePoints[index + 1].position

                    let incomingAngle = segmentAngle(from: prevPoint, to: currentPoint)
                    let outgoingAngle = segmentAngle(from: currentPoint, to: nextPoint)
                    let turn = turnAngle(incomingAngle: incomingAngle, outgoingAngle: outgoingAngle)

                    let inferredType = inferredElbowType(turnAngle: turn)
                    if inferredType != .none {
                        let item = AggregatedFittingItem(
                            fittingType: inferredType,
                            enteringSize: enteringSize,
                            exitingSize: exitingSize,
                            isInferred: true
                        )
                        let key = item.groupKey
                        if let existing = counts[key] {
                            counts[key] = (existing.0, existing.1 + 1)
                        } else {
                            counts[key] = (item, 1)
                        }
                    }
                }
            }
        }

        return counts.values
            .sorted { a, b in
                // Sort by: explicit before inferred, then by fitting type, then by size
                if a.0.isInferred != b.0.isInferred {
                    return !a.0.isInferred
                }
                if a.0.fittingType.rawValue != b.0.fittingType.rawValue {
                    return a.0.fittingType.rawValue < b.0.fittingType.rawValue
                }
                return a.0.sizeDescription < b.0.sizeDescription
            }
    }

    // Helper functions for inferred elbow detection
    func segmentAngle(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        var angle = atan2(-dy, dx) * 180 / .pi
        if angle < 0 { angle += 360 }
        return angle
    }

    func turnAngle(incomingAngle: CGFloat, outgoingAngle: CGFloat) -> CGFloat {
        var diff = outgoingAngle - incomingAngle
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return abs(diff)
    }

    func inferredElbowType(turnAngle: CGFloat) -> FittingType {
        if turnAngle < 10 {
            return .none
        } else if turnAngle >= 35 && turnAngle <= 55 {
            return .elbow45
        } else if turnAngle >= 10 {
            return .elbow90
        }
        return .none
    }

    // Aggregated pipe lengths by size
    var aggregatedPipeLengths: [(PipeSize, CGFloat)] {
        var lengths: [PipeSize: CGFloat] = [:]

        for spool in workPackage.assignedSpools {
            let pipePoints = spool.pipePoints
            for i in 0..<max(0, pipePoints.count - 1) {
                let start = pipePoints[i].position
                let end = pipePoints[i + 1].position
                let length = segmentLength(from: start, to: end)
                let size = pipePoints[i].pipeSize

                if size != .none {
                    lengths[size, default: 0] += length
                }
            }
        }

        return PipeSize.allCases.compactMap { size in
            guard let length = lengths[size], length > 0 else { return nil }
            return (size, length)
        }
    }

    var totalPipeLength: CGFloat {
        aggregatedPipeLengths.reduce(0) { $0 + $1.1 }
    }

    @ViewBuilder
    func fittingsSummaryView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FITTINGS SUMMARY")
                .font(.system(size: 11, weight: .bold))

            Divider()

            if aggregatedFittings.isEmpty {
                Text("No fittings")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                // Header
                HStack(spacing: 8) {
                    Text("Fitting")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Size")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 60, alignment: .center)
                    Text("Type")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 30, alignment: .center)
                    Text("Qty")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.15))

                // Rows
                ForEach(Array(aggregatedFittings.enumerated()), id: \.offset) { _, itemCount in
                    let (item, count) = itemCount
                    HStack(spacing: 8) {
                        Text(item.fittingType.rawValue)
                            .font(.system(size: 9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(item.sizeDescription)
                            .font(.system(size: 9))
                            .frame(width: 60, alignment: .center)
                        Text(item.isInferred ? "Inf" : "Exp")
                            .font(.system(size: 8))
                            .frame(width: 30, alignment: .center)
                            .foregroundColor(item.isInferred ? .orange : .primary)
                        Text("\(count)")
                            .font(.system(size: 9, weight: .medium))
                            .frame(width: 30, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                }

                // Totals row
                let totalFittings = aggregatedFittings.reduce(0) { $0 + $1.1 }
                HStack(spacing: 8) {
                    Text("TOTAL")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("")
                        .frame(width: 60, alignment: .center)
                    Text("")
                        .frame(width: 30, alignment: .center)
                    Text("\(totalFittings)")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.2))
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    func pipeLengthsSummaryView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PIPE LENGTHS SUMMARY")
                .font(.system(size: 11, weight: .bold))

            Divider()

            if aggregatedPipeLengths.isEmpty {
                Text("No pipe lengths")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            } else {
                // Header
                HStack(spacing: 8) {
                    Text("Pipe Size")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Total Length")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.15))

                // Rows
                ForEach(aggregatedPipeLengths, id: \.0.rawValue) { size, length in
                    HStack(spacing: 8) {
                        Text(size.shortName)
                            .font(.system(size: 9))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatFeetInches(inches: length))
                            .font(.system(size: 9, weight: .medium))
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                }

                Divider()

                // Total
                HStack(spacing: 8) {
                    Text("TOTAL")
                        .font(.system(size: 9, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(formatFeetInches(inches: totalPipeLength))
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.2))
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    func spoolListingView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SPOOLS INCLUDED (\(workPackage.assignedSpools.count))")
                .font(.system(size: 11, weight: .bold))

            Divider()

            let sortedSpools = workPackage.assignedSpools.sorted { $0.name < $1.name }
            let columns = 3
            let rows = (sortedSpools.count + columns - 1) / columns

            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 20) {
                        ForEach(0..<columns, id: \.self) { col in
                            let index = row * columns + col
                            if index < sortedSpools.count {
                                let spool = sortedSpools[index]
                                HStack(spacing: 4) {
                                    Text("•")
                                        .font(.system(size: 8))
                                        .foregroundColor(.blue)
                                    Text(spool.name)
                                        .font(.system(size: 9))
                                    if let system = spool.systemType {
                                        Text("(\(system))")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    func segmentLength(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        return sqrt(dx * dx + dy * dy) / scale
    }
}

// MARK: - Package Preview View

struct PackagePreviewView: View {
    let workPackage: WorkPackage
    let project: Project
    @Binding var isPresented: Bool

    @State private var currentPage = 0
    @State private var showingMailComposer = false
    @State private var showingMailError = false

    let pageWidth: CGFloat = 11 * 72
    let pageHeight: CGFloat = 8.5 * 72

    var totalPages: Int {
        2 + workPackage.assignedSpools.count  // Cover + BOM + spools
    }

    var sortedSpools: [Spool] {
        workPackage.assignedSpools.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let viewWidth = geometry.size.width
                let viewHeight = geometry.size.height - 100  // Leave room for controls

                // Calculate scale to fit page
                let scaleX = (viewWidth * 0.95) / pageWidth
                let scaleY = (viewHeight * 0.90) / pageHeight
                let fitScale = min(scaleX, scaleY)

                VStack(spacing: 0) {
                    // Page content area
                    ZStack {
                        Color.gray.opacity(0.2)
                            .ignoresSafeArea()

                        // Current page view
                        currentPageView()
                            .frame(width: pageWidth, height: pageHeight)
                            .background(Color.white)
                            .clipShape(Rectangle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            .scaleEffect(fitScale, anchor: .center)
                            .position(x: viewWidth / 2, y: viewHeight / 2)  // Explicitly center
                    }
                    .frame(height: viewHeight)

                    // Page navigation controls
                    VStack(spacing: 12) {
                        // Page indicator
                        Text("Page \(currentPage + 1) of \(totalPages)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Navigation buttons
                        HStack(spacing: 40) {
                            Button {
                                withAnimation {
                                    currentPage = max(0, currentPage - 1)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                            .disabled(currentPage == 0)

                            Button {
                                withAnimation {
                                    currentPage = min(totalPages - 1, currentPage + 1)
                                }
                            } label: {
                                HStack {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                            .disabled(currentPage == totalPages - 1)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Package Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showingMailComposer = true
                        } else {
                            showingMailError = true
                        }
                    } label: {
                        Label("Email Package", systemImage: "paperplane.fill")
                    }
                }
            }
            .sheet(isPresented: $showingMailComposer) {
                WorkPackageMailComposer(
                    workPackage: workPackage,
                    project: project,
                    isPresented: $showingMailComposer
                )
            }
            .alert("Cannot Send Email", isPresented: $showingMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please configure an email account in Settings to send emails.")
            }
        }
    }

    @ViewBuilder
    func currentPageView() -> some View {
        if currentPage == 0 {
            // Cover page
            PackageCoverPageView(workPackage: workPackage, project: project)
        } else if currentPage == 1 {
            // Aggregated BOM
            PackageAggregatedBOMView(workPackage: workPackage, project: project)
        } else {
            // Spool sheets
            let spoolIndex = currentPage - 2
            if spoolIndex < sortedSpools.count {
                SpoolPDFView(
                    spool: sortedSpools[spoolIndex],
                    project: project,
                    workPackage: workPackage
                )
            } else {
                Text("Page not found")
            }
        }
    }
}

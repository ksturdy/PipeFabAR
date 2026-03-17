//
//  PipeSegmentDetailView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  Detailed pipe segment view showing dimensions and specifications
//

import SwiftUI

/// Large detailed view of a pipe segment with all dimensions
struct PipeSegmentDetailView: View {
    let segmentLabel: String  // "A", "B", "C", etc.
    let pipeSize: PipeSize
    let schedule: PipeSchedule
    let length: Double?  // Length in inches (optional)
    let isBranchSegment: Bool  // Distinguish main vs branch segments
    let bubbleHidden: Bool?  // Current visibility state
    let onDismiss: () -> Void
    let onEdit: (() -> Void)?
    let onToggleBubbleVisibility: ((Bool) -> Void)?  // Callback to hide/show bubble

    @State private var selectedSchedule: PipeSchedule

    init(
        segmentLabel: String,
        pipeSize: PipeSize,
        schedule: PipeSchedule = .sch40,
        length: Double? = nil,
        isBranchSegment: Bool = false,
        bubbleHidden: Bool? = nil,
        onDismiss: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onToggleBubbleVisibility: ((Bool) -> Void)? = nil
    ) {
        self.segmentLabel = segmentLabel
        self.pipeSize = pipeSize
        self.schedule = schedule
        self.length = length
        self.isBranchSegment = isBranchSegment
        self.bubbleHidden = bubbleHidden
        self.onDismiss = onDismiss
        self.onEdit = onEdit
        self.onToggleBubbleVisibility = onToggleBubbleVisibility
        self._selectedSchedule = State(initialValue: schedule)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Segment \(segmentLabel)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text(pipeSize.shortName)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    Divider()

                    // Pipe rendering (simple cylinder view)
                    pipeRenderingView
                        .frame(height: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Divider()

                    // Bubble visibility toggle
                    bubbleVisibilitySection

                    Divider()

                    // Dimensions
                    dimensionsView
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Pipe Segment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }

                if let onEdit = onEdit {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") {
                            onEdit()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pipe Rendering

    @ViewBuilder
    private var pipeRenderingView: some View {
        GeometryReader { geo in
            let od = pipeSize.outerDiameter
            let scaleFactor = min(geo.size.width, geo.size.height) / CGFloat(od * 3)

            ZStack {
                // Side view of pipe (horizontal cylinder)
                VStack(spacing: 0) {
                    // Top line
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                        .frame(width: geo.size.width * 0.7, height: 2)

                    // Pipe body
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.7, blue: 0.4),
                                    Color(red: 0.3, green: 0.6, blue: 0.3),
                                    Color(red: 0.4, green: 0.7, blue: 0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geo.size.width * 0.7, height: CGFloat(od) * scaleFactor)

                    // Bottom line
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                        .frame(width: geo.size.width * 0.7, height: 2)
                }

                // Left end cap (ellipse)
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                    .overlay(
                        Ellipse()
                            .stroke(Color(red: 0.3, green: 0.6, blue: 0.3), lineWidth: 2)
                    )
                    .frame(width: CGFloat(od) * scaleFactor * 0.3, height: CGFloat(od) * scaleFactor)
                    .offset(x: -geo.size.width * 0.35)

                // Right end cap (ellipse)
                Ellipse()
                    .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                    .overlay(
                        Ellipse()
                            .stroke(Color(red: 0.3, green: 0.6, blue: 0.3), lineWidth: 2)
                    )
                    .frame(width: CGFloat(od) * scaleFactor * 0.3, height: CGFloat(od) * scaleFactor)
                    .offset(x: geo.size.width * 0.35)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Bubble Visibility Section

    @ViewBuilder
    private var bubbleVisibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Section Label")
                .font(.headline)
                .padding(.horizontal)

            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Section \(segmentLabel) Bubble")
                            .font(.body)
                        Text("Show or hide the section identifier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                        Text(segmentLabel)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                if let onToggle = onToggleBubbleVisibility {
                    Toggle("", isOn: Binding(
                        get: { !(bubbleHidden ?? false) },
                        set: { newValue in onToggle(!newValue) }
                    ))
                    .labelsHidden()
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }

    // MARK: - Dimensions View

    @ViewBuilder
    private var dimensionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dimensions")
                .font(.headline)

            // Schedule picker
            Picker("Schedule", selection: $selectedSchedule) {
                ForEach([PipeSchedule.sch40, PipeSchedule.sch80, PipeSchedule.sch160], id: \.self) { schedule in
                    Text(schedule.displayName).tag(schedule)
                }
            }
            .pickerStyle(.segmented)

            let od = pipeSize.outerDiameter
            let wallThickness = pipeSize.wallThickness(schedule: selectedSchedule)
            let id = od - (2 * wallThickness)

            dimensionRow(label: "Nominal Size", value: pipeSize.shortName)
            dimensionRow(label: "Outer Diameter", value: formatDimension(od))
            dimensionRow(label: "Wall Thickness", value: formatDimension(wallThickness))
            dimensionRow(label: "Inner Diameter", value: formatDimension(id))

            if let length = length {
                dimensionRow(label: "Length", value: formatLength(length))
            }

            Text("Per ASME B36.10M")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Helper Views

    private func dimensionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 4)
    }

    private func formatDimension(_ inches: Double) -> String {
        if inches < 1.0 {
            // Show as decimal for small dimensions
            return String(format: "%.3f\"", inches)
        } else {
            // Show as decimal for larger dimensions
            return String(format: "%.2f\"", inches)
        }
    }

    private func formatLength(_ inches: Double) -> String {
        let feet = Int(inches / 12)
        let remainingInches = inches.truncatingRemainder(dividingBy: 12)

        if feet > 0 {
            if remainingInches > 0.01 {
                return String(format: "%d'-%.2f\"", feet, remainingInches)
            } else {
                return String(format: "%d'-0\"", feet)
            }
        } else {
            return String(format: "%.2f\"", inches)
        }
    }
}

#Preview {
    PipeSegmentDetailView(
        segmentLabel: "A",
        pipeSize: .four,
        schedule: .sch40,
        length: 48.0,
        isBranchSegment: false,
        bubbleHidden: false,
        onDismiss: {},
        onEdit: { print("Edit") },
        onToggleBubbleVisibility: { hidden in print("Toggle bubble: \(hidden)") }
    )
}

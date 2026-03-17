//
//  FittingDetailView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-02-15.
//  Detailed fitting view showing accurate dimensions and isometric rendering
//

import SwiftUI

/// Large detailed view of a fitting with all dimensions
struct FittingDetailView: View {
    let fittingType: FittingType
    let pipeSize: PipeSize
    let onDismiss: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var selectedRating: FlangeRating = .class150
    @State private var selectedValveType: ValveType = .gate
    @State private var showingDeleteConfirmation = false

    /// Catalog entry for the current fitting (if available from Weldbend)
    private var catalogEntry: ManufacturerCatalogEntry? {
        WeldbendCatalog.entry(for: fittingType, pipeSize: pipeSize)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(fittingType.rawValue)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(pipeSize.shortName)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    Divider()

                    // Product image / rendering
                    fittingRenderingView
                        .frame(height: 300)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Divider()

                    // Dimensions
                    dimensionsView
                        .padding(.horizontal)

                    // Catalog info (Weldbend)
                    if catalogEntry != nil {
                        Divider()

                        catalogInfoSection
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Fitting Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Label("Edit Fitting", systemImage: "pencil")
                            }
                        }

                        if let onDelete = onDelete {
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Remove Fitting", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Remove Fitting?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    onDelete?()
                    onDismiss()
                }
            } message: {
                Text("This will remove the \(fittingType.rawValue) from this point.")
            }
        }
    }

    /// Product image name for the fitting type (independent of pipe size)
    private var fittingImageName: String? {
        switch fittingType {
        case .elbow90:  return "FittingImages/weldbend_elbow90"
        case .elbow45:  return "FittingImages/weldbend_elbow45"
        case .tee:      return "FittingImages/weldbend_tee"
        case .reducer:  return "FittingImages/weldbend_reducer"
        case .cap:      return "FittingImages/weldbend_cap"
        case .flange:   return "FittingImages/weldbend_flange_wn"
        default:        return nil
        }
    }

    // MARK: - Fitting Rendering

    @ViewBuilder
    private var fittingRenderingView: some View {
        ZStack {
            if let imageName = fittingImageName,
               UIImage(named: imageName)?.cgImage != nil {
                // Weldbend product image available
                VStack(spacing: 8) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 240)
                        .padding(.top, 12)

                    if let entry = catalogEntry {
                        Text("Weldbend\u{00AE} \(entry.partNumber)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                }
            } else {
                // Fallback to existing renderings or placeholder
                switch fittingType {
                case .flange:
                    flangeDetailRendering

                case .elbow90, .elbow45:
                    elbowDetailRendering

                case .tee:
                    fittingPlaceholder(systemImage: "arrow.triangle.branch", label: "Tee")

                case .valve:
                    fittingPlaceholder(systemImage: "valve.fill", label: "Valve")

                case .reducer:
                    fittingPlaceholder(systemImage: "arrow.right.arrow.left", label: "Reducer")

                case .coupling:
                    fittingPlaceholder(systemImage: "link", label: "Coupling")

                case .cap:
                    fittingPlaceholder(systemImage: "capsule", label: "Cap")

                case .none:
                    EmptyView()
                }
            }
        }
    }

    /// Placeholder view shown when no product image is available
    private func fittingPlaceholder(systemImage: String, label: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text(label)
                .font(.title3)
                .foregroundColor(.secondary)

            if let entry = catalogEntry {
                Text("Weldbend\u{00AE} \(entry.partNumber)")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            Text("Drop product image into Assets")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
        }
    }

    // MARK: - Elbow Detail Rendering

    @ViewBuilder
    private var elbowDetailRendering: some View {
        GeometryReader { geo in
            let centerToFace = fittingType.centerToFace(pipeSize: pipeSize)
            let radius = fittingType.elbowRadius(pipeSize: pipeSize)
            let pipeOD = pipeSize.outerDiameter
            let angle = fittingType == .elbow90 ? 90.0 : 45.0

            // Total extent of the elbow from center point to farthest edge
            // In both X and Y directions: radius + centerToFace
            let totalExtent = radius + centerToFace

            // Add space for dimension lines (in real inches)
            let dimLineSpace = 2.0 // Extra space for dimension lines
            let totalDimension = totalExtent + dimLineSpace

            // Scale to fit in available space (leave some margin)
            let scaleFactor = min(geo.size.width, geo.size.height) * 0.4 / CGFloat(totalDimension)

            ZStack {
                // Draw the elbow shape and dimensions
                ElbowTechnicalDrawing(
                    centerToFace: centerToFace,
                    bendRadius: radius,
                    pipeOD: pipeOD,
                    angle: angle,
                    scaleFactor: scaleFactor
                )
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Flange Detail Rendering

    @ViewBuilder
    private var flangeDetailRendering: some View {
        GeometryReader { geo in
            let dimensions = pipeSize.flangeDimensions(rating: selectedRating)
            let scaleFactor = min(geo.size.width, geo.size.height) / CGFloat(dimensions.outerDiameter * 2.5)

            ZStack {
                // Outer flange circle
                Circle()
                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .frame(
                        width: CGFloat(dimensions.outerDiameter) * scaleFactor,
                        height: CGFloat(dimensions.outerDiameter) * scaleFactor
                    )

                // Raised face circle
                Circle()
                    .fill(Color(red: 0.75, green: 0.75, blue: 0.75))
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .frame(
                        width: CGFloat(dimensions.raisedFaceDiameter) * scaleFactor,
                        height: CGFloat(dimensions.raisedFaceDiameter) * scaleFactor
                    )

                // Bolt holes
                ForEach(0..<dimensions.boltHoleCount, id: \.self) { index in
                    let angle = (2 * .pi * Double(index)) / Double(dimensions.boltHoleCount)
                    let radius = CGFloat(dimensions.boltCircleDiameter / 2.0) * scaleFactor
                    let holeSize = CGFloat(dimensions.boltHoleDiameter) * scaleFactor

                    Circle()
                        .fill(Color.white)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .frame(width: holeSize, height: holeSize)
                        .offset(
                            x: radius * cos(angle),
                            y: radius * sin(angle)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Catalog Info Section

    private var catalogInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manufacturer")
                .font(.headline)

            if let entry = catalogEntry {
                catalogRow(label: "Manufacturer", value: entry.manufacturer)
                catalogRow(label: "Part Number", value: entry.partNumber)
                catalogRow(label: "Material", value: entry.material)
                catalogRow(label: "Schedule", value: entry.schedule)
                catalogRow(label: "Weight (approx)", value: WeldbendCatalog.weightString(fittingType: fittingType, pipeSize: pipeSize))
                catalogRow(label: "Standard", value: entry.standard)
            }
        }
    }

    private func catalogRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .font(.system(.body, design: .monospaced))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Dimensions View

    @ViewBuilder
    private var dimensionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dimensions")
                .font(.headline)

            switch fittingType {
            case .flange:
                flangeDimensionsSection

            case .elbow90, .elbow45:
                elbowDimensionsSection

            case .tee:
                teeDimensionsSection

            case .valve:
                valveDimensionsSection

            case .reducer:
                reducerDimensionsSection

            default:
                Text("Dimensions not available for this fitting type")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Flange Dimensions

    private var flangeDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rating picker
            Picker("Rating", selection: $selectedRating) {
                ForEach(FlangeRating.allCases, id: \.self) { rating in
                    Text(rating.displayName).tag(rating)
                }
            }
            .pickerStyle(.segmented)

            let dimensions = pipeSize.flangeDimensions(rating: selectedRating)

            dimensionRow(label: "Flange OD", value: formatDimension(dimensions.outerDiameter))
            dimensionRow(label: "Bolt Circle", value: formatDimension(dimensions.boltCircleDiameter))
            dimensionRow(label: "Bolt Holes", value: "\(dimensions.boltHoleCount) × \(formatDimension(dimensions.boltHoleDiameter))")
            dimensionRow(label: "Thickness", value: formatDimension(dimensions.thickness))
            dimensionRow(label: "Raised Face OD", value: formatDimension(dimensions.raisedFaceDiameter))
            dimensionRow(label: "Raised Face Height", value: formatDimension(dimensions.raisedFaceHeight))

            Text("Per ASME B16.5")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Elbow Dimensions

    private var elbowDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let centerToFace = fittingType.centerToFace(pipeSize: pipeSize)
            let radius = fittingType.elbowRadius(pipeSize: pipeSize)

            dimensionRow(label: "Center to Face", value: formatDimension(centerToFace))
            dimensionRow(label: "Bend Radius", value: formatDimension(radius))
            dimensionRow(label: "Type", value: fittingType == .elbow90 ? "90° Long Radius" : "45°")

            Text("Per ASME B16.9")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Tee Dimensions

    private var teeDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let centerToEnd = FittingType.tee.centerToFace(pipeSize: pipeSize)

            dimensionRow(label: "Center to End", value: formatDimension(centerToEnd))
            dimensionRow(label: "Run Length", value: formatDimension(centerToEnd * 2))
            dimensionRow(label: "Branch Outlet", value: pipeSize.shortName)

            Text("Per ASME B16.9")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Valve Dimensions

    private var valveDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Valve type picker
            Picker("Valve Type", selection: $selectedValveType) {
                ForEach(ValveType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            let dimensions = pipeSize.valveDimensions(valveType: selectedValveType, rating: .class150)

            dimensionRow(label: "Face to Face", value: formatDimension(dimensions.faceToFace))
            dimensionRow(label: "Body Width", value: formatDimension(dimensions.bodyWidth))
            dimensionRow(label: "Body Height", value: formatDimension(dimensions.bodyHeight))

            Text("Per ASME B16.10")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Reducer Dimensions

    private var reducerDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let length = FittingType.reducer.centerToFace(pipeSize: pipeSize)

            dimensionRow(label: "Length", value: formatDimension(length))
            dimensionRow(label: "Large End", value: pipeSize.shortName)
            dimensionRow(label: "Small End", value: "(Select smaller size)")

            Text("Per ASME B16.9")
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
}

// MARK: - Elbow Technical Drawing

struct ElbowTechnicalDrawing: View {
    let centerToFace: Double
    let bendRadius: Double
    let pipeOD: Double
    let angle: Double
    let scaleFactor: CGFloat

    var body: some View {
        Canvas { context, size in
            let scale: CGFloat = 20
            let A = CGFloat(centerToFace) * scale
            let D = CGFloat(pipeOD) * scale
            let R = CGFloat(bendRadius) * scale

            // Isometric projection angles
            let isoX: CGFloat = cos(30 * .pi / 180)  // 0.866
            let isoY: CGFloat = sin(30 * .pi / 180)  // 0.5

            let ox = size.width / 2 - A / 2
            let oy = size.height / 2 + A / 4

            // Draw the 3D elbow with proper curves

            // Vertical pipe section (top)
            let vertTop = CGPoint(x: ox, y: oy - A)
            let vertBottom = CGPoint(x: ox, y: oy)

            // Horizontal pipe section (right)
            let horizLeft = CGPoint(x: ox, y: oy)
            let horizRight = CGPoint(x: ox + A, y: oy)

            // Draw outer wall of elbow with curve
            context.stroke(
                Path { path in
                    // Vertical outer edge
                    path.move(to: vertTop)
                    path.addLine(to: CGPoint(x: ox, y: oy - R * 0.3))

                    // Curved corner (outer)
                    path.addQuadCurve(
                        to: CGPoint(x: ox + R * 0.3, y: oy),
                        control: CGPoint(x: ox, y: oy)
                    )

                    // Horizontal outer edge
                    path.addLine(to: horizRight)
                },
                with: .color(.black),
                lineWidth: 2.5
            )

            // Draw inner wall with curve
            let innerOffset: CGFloat = D * 0.25
            context.stroke(
                Path { path in
                    path.move(to: CGPoint(x: ox + innerOffset * isoX, y: oy - A + innerOffset))
                    path.addLine(to: CGPoint(x: ox + innerOffset * isoX, y: oy - R * 0.2))

                    path.addQuadCurve(
                        to: CGPoint(x: ox + R * 0.2, y: oy - innerOffset * isoY),
                        control: CGPoint(x: ox + innerOffset * isoX, y: oy - innerOffset * isoY)
                    )

                    path.addLine(to: CGPoint(x: ox + A - innerOffset, y: oy - innerOffset * isoY))
                },
                with: .color(.black),
                style: StrokeStyle(lineWidth: 1.5, dash: [4, 2])
            )

            // Draw 3D depth edges
            context.stroke(
                Path { path in
                    // Top face of vertical pipe
                    path.move(to: vertTop)
                    path.addLine(to: CGPoint(x: vertTop.x + D * isoX, y: vertTop.y - D * isoY))

                    // Right face of horizontal pipe
                    path.move(to: horizRight)
                    path.addLine(to: CGPoint(x: horizRight.x + D * isoX, y: horizRight.y - D * isoY))

                    // Back edge of vertical
                    path.move(to: CGPoint(x: vertTop.x + D * isoX, y: vertTop.y - D * isoY))
                    path.addLine(to: CGPoint(x: ox + D * isoX, y: oy - R * 0.3 - D * isoY))

                    // Back curved section
                    path.addQuadCurve(
                        to: CGPoint(x: ox + R * 0.3 + D * isoX, y: oy - D * isoY),
                        control: CGPoint(x: ox + D * isoX, y: oy - D * isoY)
                    )

                    path.addLine(to: CGPoint(x: horizRight.x + D * isoX, y: horizRight.y - D * isoY))
                },
                with: .color(.black),
                lineWidth: 2.5
            )

            // Add hatching to show curved surface
            for i in stride(from: 0, to: R * 0.3, by: 8) {
                let t = i / (R * 0.3)
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: ox + i * 0.7, y: oy - (R * 0.3 - i) * 0.7))
                        path.addLine(to: CGPoint(
                            x: ox + i * 0.7 + D * isoX * 0.7,
                            y: oy - (R * 0.3 - i) * 0.7 - D * isoY * 0.7
                        ))
                    },
                    with: .color(.black.opacity(0.4)),
                    lineWidth: 0.5
                )
            }

            // Dimension lines
            let dimOffset: CGFloat = 40

            // Horizontal A
            drawDimension(
                context: context,
                from: CGPoint(x: ox, y: oy + dimOffset),
                to: CGPoint(x: ox + A, y: oy + dimOffset),
                label: String(format: "%.2f\"", centerToFace)
            )

            // Vertical A
            drawDimension(
                context: context,
                from: CGPoint(x: ox - dimOffset, y: oy),
                to: CGPoint(x: ox - dimOffset, y: oy - A),
                label: String(format: "%.2f\"", centerToFace)
            )

            // D (diameter) on right side
            drawDimension(
                context: context,
                from: CGPoint(x: ox + A + D * isoX + 15, y: oy - D * isoY),
                to: CGPoint(x: ox + A + D * isoX + 15, y: oy - D * isoY + D * 0.7),
                label: String(format: "%.2f\"", pipeOD)
            )
        }
    }

    private func drawDimension(context: GraphicsContext, from: CGPoint, to: CGPoint, label: String) {
        context.stroke(
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            },
            with: .color(.red),
            lineWidth: 1.5
        )

        let arrowSize: CGFloat = 6
        let isVertical = abs(to.x - from.x) < 1

        if isVertical {
            context.fill(
                Path { path in
                    path.move(to: from)
                    path.addLine(to: CGPoint(x: from.x - arrowSize/2, y: from.y + arrowSize))
                    path.addLine(to: CGPoint(x: from.x + arrowSize/2, y: from.y + arrowSize))
                },
                with: .color(.red)
            )
            context.fill(
                Path { path in
                    path.move(to: to)
                    path.addLine(to: CGPoint(x: to.x - arrowSize/2, y: to.y - arrowSize))
                    path.addLine(to: CGPoint(x: to.x + arrowSize/2, y: to.y - arrowSize))
                },
                with: .color(.red)
            )
        } else {
            context.fill(
                Path { path in
                    path.move(to: from)
                    path.addLine(to: CGPoint(x: from.x + arrowSize, y: from.y - arrowSize/2))
                    path.addLine(to: CGPoint(x: from.x + arrowSize, y: from.y + arrowSize/2))
                },
                with: .color(.red)
            )
            context.fill(
                Path { path in
                    path.move(to: to)
                    path.addLine(to: CGPoint(x: to.x - arrowSize, y: to.y - arrowSize/2))
                    path.addLine(to: CGPoint(x: to.x - arrowSize, y: to.y + arrowSize/2))
                },
                with: .color(.red)
            )
        }

        let midX = (from.x + to.x) / 2
        let midY = (from.y + to.y) / 2
        let offset: CGFloat = 15

        context.draw(
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.red),
            at: CGPoint(
                x: isVertical ? midX - offset * 2.5 : midX,
                y: isVertical ? midY : midY + offset
            )
        )
    }
}

#Preview {
    FittingDetailView(
        fittingType: .elbow90,
        pipeSize: .four,
        onDismiss: {},
        onEdit: { print("Edit") },
        onDelete: { print("Delete") }
    )
}

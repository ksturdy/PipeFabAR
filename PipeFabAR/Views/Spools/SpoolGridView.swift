//
//  SpoolGridView.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import SwiftUI

/// Grid layout for displaying spools
struct SpoolGridView: View {
    let spools: [Spool]
    let onSpoolTap: (Spool) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(spools) { spool in
                Button {
                    onSpoolTap(spool)
                } label: {
                    SpoolCard(spool: spool)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ScrollView {
        SpoolGridView(
            spools: [
                Spool(name: "2026-001-001", systemType: SystemType.hotWater.rawValue, status: "Draft"),
                Spool(name: "2026-001-002", systemType: SystemType.coldWater.rawValue, status: "Ready for Fabrication"),
                Spool(name: "2026-001-003", systemType: SystemType.gas.rawValue, status: "Fabricated")
            ],
            onSpoolTap: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

//
//  SectionHeader.swift
//  MisiCopy
//

import SwiftUI

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(title.uppercased())
                .font(Theme.Typography.sectionHeader())
                .tracking(0.6)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.primary)
        .padding(.bottom, 4)
    }
}

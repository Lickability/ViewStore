//
//  BannerView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI

/// Simple view to show a banner.
struct BannerView: View {
    
    /// The `Banner` to display.
    let banner: Banner
    
    var body: some View {
        HStack {
            Spacer()
            Label {
                Text(banner.title)
            } icon: {
                Image(systemName: "exclamationmark.warninglight")
            }
            .font(.headline)
            Spacer()
        }
        .padding(.vertical, 16)
        .glassEffect(.regular.tint(Color.accentColor.opacity(0.25)))
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

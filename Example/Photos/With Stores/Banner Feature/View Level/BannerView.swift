//
//  BannerView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI

/// Simple view to show a banner
struct BannerView: View {
    
    /// The `Banner` to display
    let banner: Banner
    
    var body: some View {
        HStack {
            Spacer()
            Text(banner.title)
            Spacer()
        }
    }
}

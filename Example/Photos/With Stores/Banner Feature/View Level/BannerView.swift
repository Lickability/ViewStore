//
//  BannerView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI

struct BannerView: View {
    let banner: Banner
    
    var body: some View {
        HStack {
            Spacer()
            Text(banner.title)
            Spacer()
        }
    }
}

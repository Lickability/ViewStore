//
//  PSAView.swift
//  ViewStore
//
//  Created by Kenneth Ackerson on 4/3/23.
//

import Foundation
import SwiftUI

struct PSAView: View {
    let psa: PSA
    
    var body: some View {
        HStack {
            Spacer()
            Text(psa.title)
            
            Spacer()

        }
    }
}

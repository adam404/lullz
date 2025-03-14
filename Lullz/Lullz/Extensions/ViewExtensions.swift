//
//  ViewExtensions.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

extension View {
    func withAd() -> some View {
        VStack(spacing: 0) {
            self
            AdView()
        }
    }
    
    // This extension adds a Color init from hex string if it doesn't exist
    func hexColor(_ hex: String) -> Color {
        Color(hex: hex) ?? .blue
    }
}

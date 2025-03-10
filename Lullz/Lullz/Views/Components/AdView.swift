//
//  AdView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct AdView: View {
    // State to track if the ad is loaded
    @State private var isAdLoaded = false
    
    var body: some View {
        VStack(alignment: .center) {
            if isAdLoaded {
                // Actual ad content would go here when connected to an ad network
                HStack {
                    Text("Advertisement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            } else {
                // Loading placeholder
                HStack {
                    Text("Loading Ad...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal)
        .onAppear {
            // Simulate ad loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isAdLoaded = true
            }
        }
        .accessibilityIdentifier("adBannerView")
    }
}

struct AdView_Previews: PreviewProvider {
    static var previews: some View {
        AdView()
    }
} 
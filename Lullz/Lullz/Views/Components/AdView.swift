//
//  AdView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct AdView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isAdLoaded = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showSubscription = false
    
    var body: some View {
        if subscriptionManager.hasRemovedAds {
            // User has purchased ad removal - show nothing
            EmptyView()
        } else {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    // Main ad content
                    PlaceholderAdView()
                        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    // Small remove ads button
                    Button {
                        showSubscription = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
            }
            .frame(height: 70)
            .accessibilityIdentifier("adBannerView")
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }
}

#Preview {
    VStack {
        AdView()
        Spacer()
    }
} 
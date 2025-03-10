//
//  AdBannerView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import UIKit

// Renamed to LegacyAdBannerView to avoid conflicts
struct LegacyAdBannerView: UIViewRepresentable {
    @AppStorage("showAdsEnabled") private var showAdsEnabled = true
    @State private var isAdLoaded = false
    
    func makeUIView(context: Context) -> UIView {
        // Create a placeholder UIView instead of ADBannerView (which is deprecated)
        let placeholderView = UIView(frame: .zero)
        placeholderView.backgroundColor = UIColor.secondarySystemBackground
        return placeholderView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.isHidden = !isAdLoaded || !showAdsEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: LegacyAdBannerView
        
        init(_ parent: LegacyAdBannerView) {
            self.parent = parent
        }
        
        // These methods would be implemented with the actual ad framework you choose
        func adViewDidLoad() {
            parent.isAdLoaded = true
        }
        
        func adViewDidFail(withError error: Error) {
            parent.isAdLoaded = false
            print("Failed to load ad: \(error.localizedDescription)")
        }
    }
}

// Fallback placeholder ad view for development/testing
struct PlaceholderAdView: View {
    var body: some View {
        VStack {
            Text("Advertisement")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 50)
                .overlay(
                    Text("Lullz Premium - Upgrade for ad-free experience")
                        .font(.caption)
                        .foregroundColor(.primary)
                )
        }
        .frame(height: 70)
        .padding(.horizontal)
    }
}

// Renamed to LegacyAdView to avoid conflicts with our new implementation
struct LegacyAdView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("showAdsEnabled") private var showAdsEnabled = true
    @AppStorage("useRealAds") private var useRealAds = false
    
    var body: some View {
        if !showAdsEnabled {
            EmptyView()
        } else if useRealAds {
            LegacyAdBannerView()
                .frame(height: 70)
        } else {
            PlaceholderAdView()
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

#Preview {
    VStack {
        // Use our new AdView for preview
        AdView()
        Spacer()
        PlaceholderAdView()
    }
} 
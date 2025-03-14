//
//  SubscriptionView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .padding()
                        
                        Text("Upgrade Lullz")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Choose the option that works best for you")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Premium Subscription Option
                    PurchaseOptionCard(
                        title: "Premium",
                        price: "$9.99",
                        description: "Full access to all features and ad-free experience",
                        features: [
                            "Remove all advertisements",
                            "Unlimited playback time",
                            "Access to all premium sounds",
                            "Future premium features"
                        ],
                        isSelected: true,
                        action: {
                            Task {
                                do {
                                    try await subscriptionManager.purchase(subscriptionManager.premiumSubscriptionID)
                                } catch {
                                    print("Failed to purchase: \(error.localizedDescription)")
                                    alertMessage = "Purchase failed: \(error.localizedDescription)"
                                    showAlert = true
                                }
                            }
                        }
                    )
                    
                    // Remove Ads Option
                    PurchaseOptionCard(
                        title: "Remove Ads",
                        price: "$2.99",
                        description: "Enjoy Lullz without any advertisements",
                        features: [
                            "Remove all advertisements",
                            "Keep the 15-minute timer limit"
                        ],
                        isSelected: false,
                        action: {
                            purchaseProduct(subscriptionManager.removeAdsID)
                        }
                    )
                    
                    // Extend Playback Option
                    PurchaseOptionCard(
                        title: "Unlimited Playback",
                        price: "$0.99",
                        description: "Remove the 15-minute playback limit",
                        features: [
                            "Play sounds for unlimited time",
                            "Still see advertisements"
                        ],
                        isSelected: false,
                        action: {
                            purchaseProduct(subscriptionManager.unlockLongPlaybackID)
                        }
                    )
                    
                    // Restore purchases
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .foregroundColor(.accentColor)
                    .padding(.top)
                    
                    // Terms
                    Text("All purchases are one-time and non-recurring. Prices may vary by location. Payment will be charged to your Apple ID account at the confirmation of purchase.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isPurchasing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .frame(width: 100, height: 100)
                                .shadow(radius: 5)
                        )
                }
            }
            .alert("Purchase Information", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func purchaseProduct(_ productID: String) {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchase(productID)
                
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Purchase successful! Thank you for supporting Lullz."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Purchase failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Your purchases have been restored."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Restore failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct PurchaseOptionCard: View {
    let title: String
    let price: String
    let description: String
    let features: [String]
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(price)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                if isSelected {
                    Text("Best Value")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor)
                        .cornerRadius(20)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Button(action: action) {
                Text("Purchase")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
} 

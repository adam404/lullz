//
//  SubscriptionManager.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import Foundation
import StoreKit
import OSLog

// MARK: - SubscriptionError
enum SubscriptionError: Error, LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested product could not be found"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - SubscriptionManager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    @Published private(set) var hasRemovedAds = false
    @Published private(set) var hasUnlockedLongPlayback = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseInProgress = false
    
    // MARK: - Product IDs
    let premiumSubscriptionID = "com.adamscott.lullz.premium"
    let removeAdsID = "com.adamscott.lullz.removeads"
    let unlockLongPlaybackID = "com.adamscott.lullz.unlongplayback"
    
    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let logger = Logger(subsystem: "com.adamscott.lullz", category: "Subscriptions")
    
    // MARK: - Initialization
    private init() {
        // Load purchase status from UserDefaults
        self.hasRemovedAds = UserDefaults.standard.bool(forKey: "hasRemovedAds")
        self.hasUnlockedLongPlayback = UserDefaults.standard.bool(forKey: "hasUnlockedLongPlayback")
        
        // Start transaction listener
        updateListenerTask = listenForTransactions()
        
        // Request products from App Store
        Task {
            await requestProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: [
                premiumSubscriptionID,
                removeAdsID,
                unlockLongPlaybackID
            ])
            
            self.products = storeProducts
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    func purchase(_ productID: String) async throws {
        guard let product = products.first(where: { $0.id == productID }) else {
            logger.error("Product not found: \(productID)")
            throw SubscriptionError.productNotFound
        }
        
        self.purchaseInProgress = true
        defer { self.purchaseInProgress = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                do {
                    let transaction = try await verification.payloadValue
                    handleTransaction(transaction)
                    await transaction.finish()
                } catch {
                    logger.error("Transaction verification failed: \(error.localizedDescription)")
                    throw SubscriptionError.verificationFailed
                }
                
            case .userCancelled:
                logger.info("User cancelled purchase")
                
            case .pending:
                logger.info("Purchase pending")
                
            @unknown default:
                logger.warning("Unknown purchase result")
            }
            
        } catch let subscriptionError as SubscriptionError {
            throw subscriptionError
        } catch {
            logger.error("Failed to purchase: \(error.localizedDescription)")
            throw SubscriptionError.purchaseFailed(error)
        }
    }
    
    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch {
            logger.error("Failed to restore purchases: \(error.localizedDescription)")
            throw SubscriptionError.purchaseFailed(error)
        }
    }
    
    // MARK: - Private Methods
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await result.payloadValue
                    await MainActor.run {
                        self.handleTransaction(transaction)
                    }
                    await transaction.finish()
                } catch {
                    self.logger.error("Transaction failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) {
        // Check what product was purchased
        let productID = transaction.productID
        
        if transaction.revocationDate == nil {
            // Transaction is valid
            if productID == premiumSubscriptionID {
                updatePurchaseStatus(hasRemovedAds: true, hasUnlockedLongPlayback: true)
            } else if productID == removeAdsID {
                updatePurchaseStatus(hasRemovedAds: true, hasUnlockedLongPlayback: self.hasUnlockedLongPlayback)
            } else if productID == unlockLongPlaybackID {
                updatePurchaseStatus(hasRemovedAds: self.hasRemovedAds, hasUnlockedLongPlayback: true)
            }
        } else {
            // Transaction was revoked
            if productID == premiumSubscriptionID {
                updatePurchaseStatus(hasRemovedAds: false, hasUnlockedLongPlayback: false)
            } else if productID == removeAdsID {
                updatePurchaseStatus(hasRemovedAds: false, hasUnlockedLongPlayback: self.hasUnlockedLongPlayback)
            } else if productID == unlockLongPlaybackID {
                updatePurchaseStatus(hasRemovedAds: self.hasRemovedAds, hasUnlockedLongPlayback: false)
            }
        }
    }
    
    private func updatePurchaseStatus(hasRemovedAds: Bool, hasUnlockedLongPlayback: Bool) {
        self.hasRemovedAds = hasRemovedAds
        self.hasUnlockedLongPlayback = hasUnlockedLongPlayback
        
        // Persist to UserDefaults
        UserDefaults.standard.set(hasRemovedAds, forKey: "hasRemovedAds")
        UserDefaults.standard.set(hasUnlockedLongPlayback, forKey: "hasUnlockedLongPlayback")
    }
} 

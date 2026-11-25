//
//  StorefrontHelper.swift
//  Side Search
//
//  Created by Cizzuk on 2026/11/25.
//

import StoreKit

final class StorefrontHelper {
    private static let lastStorefrontUserDefaultsKey = "lastStorefrontRegion"
    static let shared = StorefrontHelper()

    private var storefrontObserver: Task<Void, Never>?

    private init() {
        self.currentRegion = UserDefaults.standard.string(forKey: Self.lastStorefrontUserDefaultsKey)

        Task {
            if let currentStorefront = await Storefront.current {
                self.currentRegion = currentStorefront.countryCode
            }

            self.storefrontObserver = Task {
                for await storefront in Storefront.updates {
                    self.currentRegion = storefront.countryCode
                }
            }
        }
    }

    deinit {
        self.storefrontObserver?.cancel()
    }

    var currentRegion: String? {
        didSet {
            if let currentRegion, currentRegion != oldValue {
                UserDefaults.standard.set(currentRegion, forKey: Self.lastStorefrontUserDefaultsKey)
            }
        }
    }
}

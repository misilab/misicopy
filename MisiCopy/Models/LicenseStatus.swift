//
//  LicenseStatus.swift
//  MisiCopy
//

import Foundation

enum LicenseStatus: Hashable {
    /// User is in the free trial — bounded by remaining days and remaining transfers.
    case trial(daysLeft: Int, transfersLeft: Int)
    /// A valid license key has been activated.
    case licensed(email: String)
    /// Trial window has elapsed (days or transfers) and no key was provided.
    case expired

    var isUnlocked: Bool {
        switch self {
        case .licensed: return true
        case .trial(let d, let t): return d > 0 && t > 0
        case .expired: return false
        }
    }
}

enum LicenseConfig {
    static let trialDays = 7
    static let trialTransfers = 25
    static let machinesPerLicense = 2
    static let priceLabel = "79,90 €"
    static let purchaseURL = "https://payhip.com/b/ITG5N"
    /// Embedded HMAC secret used to verify keys. CHANGE THIS BEFORE SHIPPING.
    static let activationSecret = "SFdn24PFXu5axNMG7qhZojUNCCq5NEvPpWQTMkuoja8NEecJq3WetsLF+amMF1zE"
}

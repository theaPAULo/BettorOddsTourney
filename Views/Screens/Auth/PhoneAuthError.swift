//
//  PhoneAuthError.swift
//  BettorOdds
//
//  Created by Paul Soni on 2/5/25.
//


//
//  PhoneAuthError.swift
//  BettorOdds
//
//  Created by Assistant on 2/5/25
//  Version: 1.0.0
//

import Foundation

enum PhoneAuthError: LocalizedError {
    case invalidPhoneNumber
    case invalidVerificationCode
    case tooManyRequests
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid US phone number"
        case .invalidVerificationCode:
            return "Invalid verification code. Please try again"
        case .tooManyRequests:
            return "Too many attempts. Please try again later"
        case .unknown:
            return "An error occurred. Please try again"
        }
    }
}
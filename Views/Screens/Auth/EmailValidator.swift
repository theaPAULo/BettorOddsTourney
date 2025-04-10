//
//  EmailValidator.swift
//  BettorOdds
//
//  Created by Paul Soni on 1/31/25.
//


//
//  EmailValidator.swift
//  BettorOdds
//
//  Created by Claude on 1/31/25.
//  Version: 1.0.0
//

import Foundation

struct EmailValidator {
    /// Validates an email address using standard pattern matching
    static func isValid(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Returns a validation message if email is invalid
    static func validationMessage(for email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        if !isValid(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
}
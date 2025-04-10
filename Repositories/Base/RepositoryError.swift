//
//  RepositoryError.swift
//  BettorOdds
//
//  Created by Paul Soni on 4/9/25
//  Version: 1.0.0 - Initial implementation
//

import Foundation

enum RepositoryError: Error, LocalizedError {
    case networkError
    case cacheError
    case itemNotFound
    case invalidData
    case operationNotSupported
    case authorizationError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connectivity issue. Please check your connection and try again."
        case .cacheError:
            return "Failed to read or write to cache."
        case .itemNotFound:
            return "The requested item could not be found."
        case .invalidData:
            return "Data received was invalid or corrupted."
        case .operationNotSupported:
            return "This operation is not supported."
        case .authorizationError:
            return "You don't have permission to perform this action."
        }
    }
}

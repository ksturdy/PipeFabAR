//
//  UserProfile.swift
//  PipeFabAR
//
//  Created by Claude on 2026-01-30.
//

import Foundation

/// User profile settings stored in UserDefaults
class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var name: String {
        didSet { UserDefaults.standard.set(name, forKey: "userProfile_name") }
    }

    @Published var phoneNumber: String {
        didSet { UserDefaults.standard.set(phoneNumber, forKey: "userProfile_phoneNumber") }
    }

    @Published var email: String {
        didSet { UserDefaults.standard.set(email, forKey: "userProfile_email") }
    }

    private init() {
        self.name = UserDefaults.standard.string(forKey: "userProfile_name") ?? ""
        self.phoneNumber = UserDefaults.standard.string(forKey: "userProfile_phoneNumber") ?? ""
        self.email = UserDefaults.standard.string(forKey: "userProfile_email") ?? ""
    }

    /// Check if user has entered profile info
    var hasProfile: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Formatted display for documents
    var displayName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "Not Set" : name
    }

    var displayPhone: String {
        phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty ? "" : phoneNumber
    }

    var displayEmail: String {
        email.trimmingCharacters(in: .whitespaces).isEmpty ? "" : email
    }
}

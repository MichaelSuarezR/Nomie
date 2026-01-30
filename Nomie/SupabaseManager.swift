//
//  SupabaseManager.swift
//  Nomie
//

import Foundation
import Supabase

enum SupabaseManager {
    static let shared: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            let url = URL(string: urlString)
        else {
            preconditionFailure("Missing SupabaseURL or SupabaseAnonKey in Info.plist")
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }()
}


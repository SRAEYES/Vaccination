//
//  VaccineStorage.swift
//  Vaccination
//
//  Created by user66 on 12/12/25.
//

// VaccineStorage.swift
import Foundation

struct VaccineStorage {
    private static let key = "baseUpcomingVaccines_v1"

    static func saveBaseUpcoming(_ items: [VaccineItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        if let data = try? encoder.encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadBaseUpcoming() -> [VaccineItem] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return (try? decoder.decode([VaccineItem].self, from: data)) ?? []
    }
}

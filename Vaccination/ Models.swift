//
//   Models.swift
//  Vaccination
//
//  Created by user66 on 12/12/25.
//

// Models.swift
import Foundation

// MARK: Vaccine model
struct VaccineItem: Codable, Equatable {
    let id: String
    var name: String
    var subtitle: String   // age bucket or description
    var dueDate: Date?

    init(id: String = UUID().uuidString, name: String, subtitle: String, dueDate: Date? = nil) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.dueDate = dueDate
    }
}

// MARK: Delegate protocol for add screen
protocol AddVaccineDelegate: AnyObject {
    func addVaccineViewController(_ vc: AddVaccineViewController, didCreate vaccine: VaccineItem)
}

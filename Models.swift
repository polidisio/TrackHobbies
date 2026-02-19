import Foundation
import SwiftData

// Enums moved to Models/Enums.swift
// ResourceType and ProgressStatus are defined there

struct PendingItem: Identifiable, Codable {
    var id: UUID
    var resourceId: UUID
    var title: String
    var dueDate: Date?
    var completed: Bool
}

struct Resource: Identifiable, Codable {
    var id: UUID
    var type: ResourceType
    var title: String
    var externalId: String?
    var imageURL: String?
    var summary: String?
    var authorOrCreator: String?
    var userRating: Double?
    var status: ProgressStatus
    var timeSpentHours: Double?
    var lastUpdated: Date?
    var pendings: [PendingItem]?
}

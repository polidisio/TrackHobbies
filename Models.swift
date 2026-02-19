import Foundation

// Core domain models (structs for MVP). Persistence layer (Core Data) will be wired later.

enum ResourceType: String, Codable {
    case book
    case series
    case game
}

enum ProgressStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
}

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

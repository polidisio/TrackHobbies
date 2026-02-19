import Foundation
import SwiftData

@Model
final class ResourceEntity {
    @Attribute(.unique) var id: UUID
    var type: String
    var title: String
    var externalId: String?
    var imageURL: String?
    var summary: String?
    var authorOrCreator: String?
    var userRating: Double?
    var status: String
    var timeSpentHours: Double?
    var lastUpdated: Date?
    @Relationship(deleteRule: .cascade) var pendings: [PendingItemEntity]?
    
    init(
        id: UUID = UUID(),
        type: ResourceType,
        title: String,
        externalId: String? = nil,
        imageURL: String? = nil,
        summary: String? = nil,
        authorOrCreator: String? = nil,
        userRating: Double? = nil,
        status: ProgressStatus = .notStarted,
        timeSpentHours: Double? = nil,
        lastUpdated: Date? = nil
    ) {
        self.id = id
        self.type = type.rawValue
        self.title = title
        self.externalId = externalId
        self.imageURL = imageURL
        self.summary = summary
        self.authorOrCreator = authorOrCreator
        self.userRating = userRating
        self.status = status.rawValue
        self.timeSpentHours = timeSpentHours
        self.lastUpdated = lastUpdated
    }
    
    var resourceType: ResourceType {
        get { ResourceType(rawValue: type) ?? .book }
        set { type = newValue.rawValue }
    }
    
    var progressStatus: ProgressStatus {
        get { ProgressStatus(rawValue: status) ?? .notStarted }
        set { status = newValue.rawValue }
    }
}

@Model
final class PendingItemEntity {
    @Attribute(.unique) var id: UUID
    var resourceId: UUID
    var title: String
    var dueDate: Date?
    var completed: Bool
    
    init(
        id: UUID = UUID(),
        resourceId: UUID,
        title: String,
        dueDate: Date? = nil,
        completed: Bool = false
    ) {
        self.id = id
        self.resourceId = resourceId
        self.title = title
        self.dueDate = dueDate
        self.completed = completed
    }
}

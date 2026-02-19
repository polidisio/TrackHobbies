# AGENTS.md - TrackHobbies Development Guide

## Project Overview
- **Project**: TrackHobbies - iOS app for tracking books, series, and games
- **Platform**: iPhone + iPad (SwiftUI)
- **Language**: Swift 5.9+
- **Architecture**: MVVM with services layer
- **Persistence**: CloudKit + local storage (Core Data planned)

---

## Build & Run Commands

### Prerequisites
- Xcode 15+
- XcodeGen (install via `brew install xcodegen`)
- iOS Simulator or physical device

### Generating Xcode Project
```bash
xcodegen generate
```

### Building the App
```bash
# Build for iOS Simulator
xcodebuild -scheme TrackHobbies -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Build for specific simulator
xcodebuild -scheme TrackHobbies -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for generic iOS device
xcodebuild -scheme TrackHobbies -configuration Debug -destination generic/platform=iOS build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -scheme TrackHobbies -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run specific test class
xcodebuild test -scheme TrackHobbies -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TestClassName

# Run specific test method
xcodebuild test -scheme TrackHobbies -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:TestClassName/testMethodName
```

### Linting
SwiftLint is recommended:
```bash
# Install (if needed)
brew install swiftlint

# Run lint
swiftlint
```

### Code Signing (for physical devices)
```bash
xcodebuild -scheme TrackHobbies -configuration Debug -destination 'platform=iOS,name=Your Device' CODE_SIGN_IDENTITY="Your Team" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

---

## Code Style Guidelines

### Imports
- Use single-line imports
- Group imports: Foundation, SwiftUI, third-party, then app modules
- Example:
```swift
import Foundation
import SwiftUI
import Combine
```

### Naming Conventions
- **Types/Enums/Protocols**: PascalCase (`Resource`, `ProgressStatus`, `OpenLibraryService`)
- **Properties/Variables/Parameters**: camelCase (`userRating`, `timeSpentHours`, `externalId`)
- **Constants**: camelCase with meaningful names (`baseURL`, `shared`)
- **Files**: Match type name (e.g., `OpenLibraryService.swift` contains `OpenLibraryService`)
- **ViewModels**: Suffix with `ViewModel` (e.g., `BooksViewModel`)

### Type Guidelines
- Use Swift native types (`String`, `Int`, `Double`, `Bool`, `Date`)
- Use `UUID` for identifiers
- Use optionals (`?`) when value may be absent
- Use value types (`struct`) for models; `class` only for services/singletons
- Conform models to `Codable` for JSON/persistence support

### Struct vs Class Usage
- **Use `struct`** for: Domain models, DTOs, View models, lightweight data containers
- **Use `class`** for: Services with shared state/singletons, delegates
- **Use `final class`** when inheritance is not needed (performance + intent)

### Enums
- Use enums for fixed sets of values
- Raw values for strings: `case book` with `String` raw type
- Use associated values when needed
```swift
enum ResourceType: String, Codable {
    case book
    case series
    case game
}
```

### Error Handling
- Use `guard` for early returns on invalid conditions
- Use `if let` / `guard let` for optional unwrapping
- Use `Result` type for async operations when needed
- Example:
```swift
guard var components = URLComponents(string: baseURL) else {
    completion([]); return
}
```

### Async/Await (Preferred for New Code)
- Use modern Swift concurrency (`async/await`) over completion handlers when possible
- Mark async functions with `throws` for error propagation
- Use `@MainActor` for UI-bound code

### Services Layer
- Use singleton pattern with `static let shared`
- Private initializer to prevent instantiation
- Keep services stateless where possible
- Example:
```swift
final class OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org/search.json"
    
    private init() {}
}
```

### SwiftUI Views
- Use `@ViewBuilder` for complex view composition
- Add `PreviewProvider` for each view:
```swift
struct ResourceRow_Previews: PreviewProvider {
    static var previews: some View {
        ResourceRow(title: "Dune", author: "Frank Herbert", rating: 4.5)
            .previewLayout(.sizeThatFits)
    }
}
```
- Use meaningful property names for view inputs
- Keep views focused: single responsibility per view

### Model Definitions
- All models should be `Identifiable` when used in lists
- Conform to `Codable` for persistence/API
- Use clear, descriptive property names
```swift
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
```

### Comments
- Avoid unnecessary comments; code should be self-documenting
- Use comments only for: complex logic explanation, TODOs, known limitations
- No header/divider comments in files

### Formatting
- 4-space indentation (Xcode default)
- No trailing whitespace
- One blank line between top-level declarations
- Max line length: ~120 characters (soft limit)
- Use type inference when obvious

### API Response Models
- Use private nested structs for API DTOs
- Use separate domain models for app logic
- Map DTOs to domain models in service layer

---

## Project Structure
```
TrackHobbies/
├── AppMain.swift           # App entry point (@main)
├── Models.swift            # Domain models (Resource, PendingItem, enums)
├── ContentView.swift       # Main TabView with navigation
├── Services/               # API services
│   ├── OpenLibraryService.swift
│   ├── TVMazeService.swift
│   └── RAWGService.swift
├── Views/                  # SwiftUI views
│   └── ResourceRow.swift
├── ViewModels/             # MVVM view models
├── Utils/                  # Utilities
│   ├── CSVExporter.swift
│   └── NotionExporter.swift
└── Sync/                   # CloudKit sync
    └── CloudKitSync.swift
```

---

## Testing Strategy
- Create test classes in `Tests/` directory
- Test naming: `ClassNameTests`
- Test methods: `testMethodName`
- Use XCTest framework
- Example test structure:
```swift
import XCTest
@testable import TrackHobbies

final class OpenLibraryServiceTests: XCTestCase {
    func testSearchReturnsResults() async throws {
        // Test implementation
    }
}
```

---

## Common Tasks

### Adding a New Service
1. Create `Services/NewServiceNameService.swift`
2. Define API response DTOs (nested, private)
3. Define domain model
4. Implement service with singleton pattern
5. Add preview provider for testing

### Adding a New View
1. Create `Views/ViewName.swift`
2. Implement `View` protocol
3. Add `PreviewProvider`
4. Register in appropriate navigation

### Adding a New Model
1. Add to `Models.swift` or create new file
2. Conform to `Identifiable`, `Codable`
3. Add to relevant enum if applicable

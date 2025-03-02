import SwiftUI

/// Must be `Hashable` (and `Identifiable`) if you want to use it in a `Set<PupTask>` or `ForEach`.
struct PupTask: Identifiable, Hashable {
        let id = UUID()
        var name: String
        var isSelected: Bool
        var color: Color
    }

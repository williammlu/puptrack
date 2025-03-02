import SwiftUI

/// Morning, Afternoon, or Night slot for photos
enum PupPhotoSlot: String, CaseIterable {
    case morning, afternoon, night
    
    var displayName: String {
        rawValue.capitalized
    }
}
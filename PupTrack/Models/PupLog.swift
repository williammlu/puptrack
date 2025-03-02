import Foundation

/// A single log entry: which task and a timestamp
struct PupLog: Identifiable {
    let id = UUID()
    let taskName: String
    let timestamp: Date
}
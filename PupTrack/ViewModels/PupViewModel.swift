import SwiftUI

/// Core data model for PupTrack
@MainActor
class PupViewModel: ObservableObject {
    // MARK: Onboarding Data
    @Published var dogName: String = ""
    
    // A single list of tasks. Each PupTask can be selected (isSelected=true/false).
    @Published var tasks: [PupTask] = [
        PupTask(name: "Toothbrushing", isSelected: false, color: Color(.red)),
        PupTask(name: "Nails",         isSelected: false, color: Color(.orange)),
        PupTask(name: "Brushing Fur",  isSelected: false, color: Color(.yellow)),
        PupTask(name: "Throwing up",   isSelected: false, color: Color(.green))
    ]
    
    // Optional array if you want to store just the names of selected tasks.
    @Published var selectedTasks: [String] = []
    
    // Photos for morning, afternoon, night
    @Published var photoDict: [PupPhotoSlot: UIImage?] = [
        .morning: nil,
        .afternoon: nil,
        .night: nil
    ]
    
    // Whether we've finished onboarding
    @Published var hasOnboarded: Bool = false
    
    // MARK: Logging
    @Published var logs: [PupLog] = []
    
    // Called when user completes onboarding
    func completeOnboarding() {
//        guard !dogName.isEmpty else { return }
        hasOnboarded = true
    }
    
    // Toggle a single PupTask's isSelected
    func toggleTask(_ task: PupTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isSelected.toggle()
        }
    }
    
    // Add a custom task (auto-selected)
    func addCustomTask(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Enforce max 25 chars
        let finalName = String(trimmed.prefix(25))
        
        let newTask = PupTask(name: finalName, isSelected: true, color: Color("PastelPurple"))
        tasks.append(newTask)
    }
    
    // Update photo for a slot
    func setPhoto(slot: PupPhotoSlot, image: UIImage) {
        photoDict[slot] = image
    }
    
    // Return which slot matches current time
    func currentPhotoSlot() -> PupPhotoSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default:     return .night
        }
    }
    
    // Add a log entry
    func logTask(_ taskName: String) {
        let newLog = PupLog(taskName: taskName, timestamp: Date())
        logs.insert(newLog, at: 0)
    }
    
    // Filter logs for a specific date
    func logs(for date: Date) -> [PupLog] {
        let cal = Calendar.current
        return logs.filter {
            cal.isDate($0.timestamp, inSameDayAs: date)
        }
    }
    
    // CSV Export
    func exportLogsToCSV() -> URL? {
        let header = "Timestamp,Task\n"
        let df = ISO8601DateFormatter()
        var csv = header
        
        for entry in logs {
            csv.append("\(df.string(from: entry.timestamp)),\(entry.taskName)\n")
        }
        
        let filename = "PupTrackExport-\(Int(Date().timeIntervalSince1970)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("CSV error: \(error)")
            return nil
        }
    }
}

///// A single task in our list
//struct PupTask: Identifiable {
//    let id = UUID()
//    var name: String
//    var isSelected: Bool
//    var color: Color
//}
//
///// Time slots for photos
//enum PupPhotoSlot: String, CaseIterable {
//    case morning, afternoon, night
//}
//
///// A single log record
//struct PupLog: Identifiable {
//    let id = UUID()
//    let taskName: String
//    let timestamp: Date
//}

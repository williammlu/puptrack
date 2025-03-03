import SwiftUI

/// Core data model for PupTrack
@MainActor
class PupViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var dogName: String = ""
    
    /// A single list of tasks. Each PupTask can be selected (isSelected=true/false).
    /// We store a `colorName` string (e.g. "red") so PupTask is fully Codable.
    @Published var tasks: [PupTask] = [
        PupTask(name: "Toothbrushing", isSelected: false, colorName: "mint"),
        PupTask(name: "Cut Nails",     isSelected: false, colorName: "orange"),
        PupTask(name: "Throwing up",   isSelected: false, colorName: "yellow"),
        PupTask(name: "Brushing Fur",  isSelected: false, colorName: "pink"),
        PupTask(name: "Bath",          isSelected: false, colorName: "blue"),
    ]
    
    /// An optional array storing the names of selected tasks, if you need them separately.
    @Published var selectedTasks: [String] = []
    
    /// Instead of storing `UIImage?`, we store file paths (strings).
    /// If `photoDict[.morning] == "Photos/morning.png"`, we can reconstruct the UIImage from disk.
    @Published var photoDict: [PupPhotoSlot: String?] = [
        .morning: nil,
        .afternoon: nil,
        .night: nil
    ]
    
    /// Whether we've finished onboarding
    @Published var hasOnboarded: Bool = false
    
    /// Our logs of tasks performed, each is a PupLog with timestamp
    @Published var logs: [PupLog] = []
    
    // MARK: - File Management
    
    /// The main JSON file name we use to persist PupViewModel data
    private let dataFileName = "PupTrackData.json"
    
    // MARK: - Initialization
    
    /// Load data on init, if a file exists
    init() {
        loadEverything()
    }
    
    // MARK: - Onboarding
    
    /// Called when user completes onboarding
    func completeOnboarding() {
        // If you want to require that dogName is non-empty:
        // guard !dogName.isEmpty else { return }
        hasOnboarded = true
        saveEverything()
    }
    
    // MARK: - Tasks
    
    /// Toggle a single PupTask's isSelected, then persist
    func toggleTask(_ task: PupTask) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isSelected.toggle()
            saveEverything()
        }
    }
    
    func removeLogByID(_ id: UUID) {
            if let idx = logs.firstIndex(where: { $0.id == id }) {
                logs.remove(at: idx)
                // If you persist data, call saveEverything() here
                 saveEverything()
            }
        }
    
    func removeLogs(atOffsets offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
        // If you are persisting, call saveEverything() here, too.
         saveEverything()
    }
    
    /// Add a custom task (auto-selected), then persist
    func addCustomTask(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let finalName = String(trimmed.prefix(25))
        
        let newTask = PupTask(name: finalName, isSelected: true, colorName: "purple")
        tasks.append(newTask)
        saveEverything()
    }
    
    // MARK: - Photos
    
    /// Save a UIImage to disk as PNG, store its path in `photoDict` for PupPhotoSlot
    func setPhoto(slot: PupPhotoSlot, image: UIImage) {
        // Convert to PNG data
        guard let pngData = image.pngData() else { return }
        
        // Create /Photos subfolder if needed
        let photosFolder = documentsDirectory().appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: photosFolder, withIntermediateDirectories: true)
        
        // Name the file after the slot, e.g. "morning.png"
        let fileName = "\(slot.rawValue).png"
        let fileURL = photosFolder.appendingPathComponent(fileName)
        
        do {
            try pngData.write(to: fileURL, options: .atomic)
            // Store the relative path in photoDict
            photoDict[slot] = "Photos/\(fileName)"
            saveEverything()
        } catch {
            print("Error saving photo for \(slot): \(error)")
        }
    }
    
    /// Load a UIImage from disk if a path is in photoDict
    func getPhoto(slot: PupPhotoSlot) -> UIImage? {
        guard let pathStr = photoDict[slot] ?? nil else { return nil }
        let fullURL = documentsDirectory().appendingPathComponent(pathStr)
        guard FileManager.default.fileExists(atPath: fullURL.path) else { return nil }
        return UIImage(contentsOfFile: fullURL.path)
    }
    
    /// Which slot matches current time of day
    func currentPhotoSlot() -> PupPhotoSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default:     return .night
        }
    }
    
    // MARK: - Logs
    
    /// Add a log entry (with current time), then persist
    func logTask(_ taskName: String) {
        let newLog = PupLog(taskName: taskName, timestamp: Date())
        logs.insert(newLog, at: 0)
        saveEverything()
    }
    
    /// Add a log entry at specific time, then persist
    func logTask(_ taskName: String, at: Date) {
        let newLog = PupLog(taskName: taskName, timestamp: at)
        logs.insert(newLog, at: 0)
        saveEverything()
    }

    
    /// Filter logs for a specific date
    func logs(for date: Date) -> [PupLog] {
        let cal = Calendar.current
        return logs.filter {
            cal.isDate($0.timestamp, inSameDayAs: date)
        }
    }
    
    // MARK: - CSV Export
    
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
    
    // MARK: - Persist / Load
    
    /// Write everything (dogName, tasks, logs, etc.) to PupTrackData.json
    func saveEverything() {
        let dataToSave = PupTrackPersistedData(
            dogName: dogName,
            tasks: tasks,
            selectedTasks: selectedTasks,
            photoPaths: photoDict,
            hasOnboarded: hasOnboarded,
            logs: logs
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(dataToSave)
            let fileURL = documentsDirectory().appendingPathComponent(dataFileName)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving PupTrack data: \(error)")
        }
    }
    
    /// Load data from PupTrackData.json if it exists
    func loadEverything() {
        let fileURL = documentsDirectory().appendingPathComponent(dataFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let loaded = try decoder.decode(PupTrackPersistedData.self, from: data)
            
            self.dogName = loaded.dogName
            self.tasks = loaded.tasks
            self.selectedTasks = loaded.selectedTasks
            self.photoDict = loaded.photoPaths
            self.hasOnboarded = loaded.hasOnboarded
            self.logs = loaded.logs
        } catch {
            print("Error loading PupTrack data: \(error)")
        }
    }
    
    /// Path to our app’s Documents directory
    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - PupTrackPersistedData: The top-level codable container for JSON
struct PupTrackPersistedData: Codable {
    let dogName: String
    let tasks: [PupTask]
    let selectedTasks: [String]
    let photoPaths: [PupPhotoSlot: String?]
    let hasOnboarded: Bool
    let logs: [PupLog]
}

// MARK: - PupTask, PupPhotoSlot, PupLog remain as you had them

/// PupTask is now fully Codable (storing colorName instead of Color)
struct PupTask: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var isSelected: Bool
    var colorName: String
    
    init(id: UUID = UUID(), name: String, isSelected: Bool, colorName: String) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
        self.colorName = colorName
    }
}

/// Map colorName -> SwiftUI Color
extension PupTask {
    var color: Color {
        switch colorName.lowercased() {
        case "red":      return .red
        case "orange":   return .orange
        case "yellow":   return .yellow
        case "green":    return .green
        case "mint":     return .mint
        case "teal":     return .teal
        case "cyan":     return .cyan
        case "blue":     return .blue
        case "indigo":   return .indigo
        case "purple":   return .purple
        case "pink":     return .pink
        case "brown":    return .brown
        default:         return .gray
        }
    }
}

enum PupPhotoSlot: String, CaseIterable, Codable {
    case morning, afternoon, night
    
    var displayName: String {
        rawValue.capitalized
    }
}

struct PupLog: Identifiable, Codable {
    let id: UUID
    let taskName: String
    let timestamp: Date
    
    init(id: UUID = UUID(), taskName: String, timestamp: Date) {
        self.id = id
        self.taskName = taskName
        self.timestamp = timestamp
    }
}

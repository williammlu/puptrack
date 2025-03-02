import SwiftUI

struct PupCalendarView: View {
    @EnvironmentObject var viewModel: PupViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
    @State private var showExporter = false
    @State private var csvURL: URL?
    
    // For adding an event via long press
    @State private var showAddEventSheet = false
    @State private var addEventDate: Date? = nil
    
    let columns = 7
    let calendar = Calendar.current
    
    // Circle highlight for selected day
    let selectedCircleDiameter: CGFloat = 28
    let selectedCircleOpacity: Double = 0.3
    
    var body: some View {
        NavigationStack {
            List {
                
                // SECTION 1: Calendar top
                Section {
                    // Month Header
                    HStack {
                        Button {
                            moveMonth(-1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .padding(8)
                        }
                        Spacer()
                        Text(monthTitleString(currentMonth))
                            .font(.headline)
                        Spacer()
                        Button {
                            moveMonth(1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .listRowSeparator(.hidden)
                    // Disable selection highlight on this row
                    .selectionDisabled()
                    
                    // Calendar Grid
                    calendarGrid
                        .listRowSeparator(.hidden)
                        .listRowSelectionDisabled(true)
                }
                
                // SECTION 2: Logs for selected date
                let dayLogs = viewModel.logs(for: selectedDate)
                Section("Logs on \(formattedSelectedDate(selectedDate))") {
                    if dayLogs.isEmpty {
                        Text("No tasks logged on this day.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(dayLogs) { logItem in
                            HStack {
                                Text(logItem.taskName)
                                Spacer()
                                Text(logItem.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteLogsForSelectedDay)
                    }
                }
                
                // SECTION 3: Month summary
                let logsThisMonth = logsInMonth(currentMonth)
                let grouped = Dictionary(grouping: logsThisMonth, by: \.taskName)
                Section("\(monthTitleString(currentMonth)) Monthly Summary") {
                    if grouped.isEmpty {
                        Text("No activities recorded this month.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(grouped.keys.sorted(), id: \.self) { taskName in
                            let count = grouped[taskName]?.count ?? 0
                            HStack {
                                Text(taskName)
                                Spacer()
                                Text("\(count) time\(count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if let url = viewModel.exportLogsToCSV() {
                            csvURL = url
                            showExporter = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExporter) {
                if let csvURL {
                    ShareSheet(activityItems: [csvURL])
                }
            }
            // Show AddEventView on a long-press
            .sheet(isPresented: $showAddEventSheet) {
                if let date = addEventDate {
                    AddEventView(
                        date: date,
                        tasks: viewModel.tasks
                    ) { taskName, chosenTime in
                        let combined = combine(day: date, time: chosenTime)
                        viewModel.logTask(taskName, at: combined)
                    }
                }
            }
        }
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
            ForEach(makeDaysInMonth(for: currentMonth), id: \.self) { date in
                let dayNumber = calendar.component(.day, from: date)
                let isInMonth = isSameMonth(date, as: currentMonth)
                let dayLogs = viewModel.logs(for: date)
                let isSelected = (dateOnly(date) == dateOnly(selectedDate))
                
                // limit to 10 logs => 2 rows × 5 columns
                let limitedLogs = Array(dayLogs.prefix(10))
                let row1 = Array(limitedLogs.prefix(5))
                let row2 = Array(limitedLogs.dropFirst(5))
                
                VStack(spacing: 2) {
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(Color.gray.opacity(selectedCircleOpacity))
                                .frame(width: selectedCircleDiameter, height: selectedCircleDiameter)
                        }
                        Text("\(dayNumber)")
                            .font(.callout)
                            .foregroundColor(isInMonth ? .primary : .gray)
                    }
                    // dot rows
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(row1, id: \.id) { log in
                                let c = viewModel.tasks.first(where: { $0.name == log.taskName })?.color ?? .gray
                                Circle().fill(c).frame(width: 5, height: 5)
                            }
                        }
                        if !row2.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(row2, id: \.id) { log in
                                    let c = viewModel.tasks.first(where: { $0.name == log.taskName })?.color ?? .gray
                                    Circle().fill(c).frame(width: 5, height: 5)
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 40)
                // tap to select date
                .onTapGesture {
                    selectedDate = date
                }
                // long-press => add event
                .simultaneousGesture(
                    LongPressGesture().onEnded { _ in
                        addEventDate = date
                        showAddEventSheet = true
                    }
                )
                // only this cell is interactive
                .contentShape(Rectangle())
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Deletion
    private func deleteLogsForSelectedDay(_ offsets: IndexSet) {
        let logsThatDay = viewModel.logs(for: selectedDate)
        for offset in offsets {
            let item = logsThatDay[offset]
            viewModel.removeLogByID(item.id)
        }
    }
    
    // MARK: - Helpers
    private func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func makeDaysInMonth(for base: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: base) else { return [] }
        
        var days: [Date] = []
        // Leading offset
        var current = interval.start
        let weekdayOffset = calendar.component(.weekday, from: current) - calendar.firstWeekday
        for _ in 0..<(weekdayOffset < 0 ? weekdayOffset + 7 : weekdayOffset) {
            if let prev = calendar.date(byAdding: .day, value: -1, to: current) {
                current = prev
                days.insert(current, at: 0)
            }
        }
        
        // Fill entire month
        current = interval.start
        while current < interval.end {
            days.append(current)
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: current) {
                current = nextDay
            } else {
                break
            }
        }
        
        // Trailing offset
        while days.count % 7 != 0 {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: days.last!) {
                days.append(nextDay)
            } else { break }
        }
        return days
    }
    
    private func isSameMonth(_ d1: Date, as d2: Date) -> Bool {
        calendar.component(.month, from: d1) == calendar.component(.month, from: d2) &&
        calendar.component(.year, from: d1) == calendar.component(.year, from: d2)
    }
    
    private func dateOnly(_ date: Date) -> Date {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: comps) ?? date
    }
    
    private func monthTitleString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func logsInMonth(_ date: Date) -> [PupLog] {
        guard let range = calendar.dateInterval(of: .month, for: date) else { return [] }
        return viewModel.logs.filter { range.contains($0.timestamp) }
    }
    
    private func formattedSelectedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
    
    private func combine(day: Date, time: Date) -> Date {
        // Merge day + time
        let dayComps = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComps = calendar.dateComponents([.hour, .minute], from: time)
        
        var merged = DateComponents()
        merged.year = dayComps.year
        merged.month = dayComps.month
        merged.day = dayComps.day
        merged.hour = timeComps.hour
        merged.minute = timeComps.minute
        
        return calendar.date(from: merged) ?? Date()
    }
}

/// AddEventView with an init guaranteeing we have a default selectedTaskName
struct AddEventView: View {
    let date: Date
    let tasks: [PupTask]
    let onConfirm: (String, Date) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTaskName: String
    @State private var selectedTime: Date
    
    init(
        date: Date,
        tasks: [PupTask],
        onConfirm: @escaping (String, Date) -> Void
    ) {
        self.date = date
        self.tasks = tasks
        self.onConfirm = onConfirm
        
        // Default selected task = first if possible
        let defaultTask = tasks.first?.name ?? ""
        // Default time = 12 PM
        let cal = Calendar.current
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
        
        _selectedTaskName = State(initialValue: defaultTask)
        _selectedTime = State(initialValue: noon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Pick a Category") {
                    Picker("Task", selection: $selectedTaskName) {
                        ForEach(tasks, id: \.name) { t in
                            Text(t.name).tag(t.name)
                        }
                    }
                }
                
                Section("Select Time") {
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !selectedTaskName.isEmpty else { return }
                        onConfirm(selectedTaskName, selectedTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

// Basic ShareSheet if you need it
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
